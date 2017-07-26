<?php
defined('BASEPATH') OR exit('No direct script access allowed');
require_once(FCPATH.'vendor/autoload.php');

class Grpc extends CI_Controller {


	private $grpc_host = "";


   
	private $serviceDatas = [];

	public function __construct()
    {
    	parent::__construct();
    	$this->load->helper('file');
    	/*
    	if (strpos($_SERVER["HTTP_HOST"], "appweb") === FALSE) {
    		$this->grpc_host = "10.32.186.11:6565";
    	}
    	else {
    		$this->grpc_host = "app.i-dalian.cn:56565";
    	}
    	*/
    	$protos = get_filenames(APPPATH.'proto/');
    	foreach ($protos as $proto) {
    		require_once(APPPATH.'proto/'.$proto);
    		//var_dump($proto);
    	}
    //	$serviceDatas = [];
    	foreach ($protos as $proto) {
    		$fileName = explode(".", $proto)[0];
    		$className = "sc\\".strtolower($fileName)."\\".$fileName."ServiceClient";
            $serviceTitle = "sc.".strtolower($fileName).".".$fileName;
    		if (class_exists($className)) {
    			$this->add_service($className, $serviceTitle, $this->serviceDatas);
    		}
    	}
    }

     

    private function add_service($className, $serviceTitle, &$serviceDatas) {
    	$serviceMeta = new ReflectionClass($className); 
    	$serviceMethods = $serviceMeta->getMethods(ReflectionMethod::IS_PUBLIC);
    	$data = [];
    	$data["name"] = $className;
        $data["title"] = $serviceTitle;
    	$data["methods"] = [];
    	foreach ($serviceMethods as $method) {
    		$name = $method->name;
    		$class = $method->class;
    		if ($class != $serviceMeta->name) {
    			continue;
    		}
    		if ($name == "__construct") {
    			continue;
    		}
    		$methodData = [];
    		$methodData["name"] = $name;
    		$methodData["parameters"] = [];
    		foreach ($method->getParameters() as $parameter) {
    			$parameterData = [];
    			if ($parameter->name != "argument") {
    				continue;
    			}
    			$parameterData["name"] = $parameter->name;
    			$type = $parameter->getClass()->name;
    			$parameterMeta = new ReflectionClass($type);
    			$parameterData["class"] = $type;
    			$parameterData["fields"] = [];
    			$fields = call_user_func($type.'::descriptor')->getFields();
    			
    			$this->add_fields($fields, $parameterData["fields"]);
    			$methodData["parameters"][] = $parameterData;
    		
    		}

    		$data["methods"][] = $methodData;
    	}
    	$serviceDatas[] = $data;
    }
    private function add_fields($fields, &$fieldDatas) {
    	foreach ($fields as $field) {
    		$fieldData = [];
    		$fieldData['name'] = $field->name;
			$fieldData['type'] = $field->type;
			
			if ($field->type == \DrSlump\Protobuf::TYPE_MESSAGE) {
				$fieldData['ref'] = [];
				$fieldData['class'] = $field->reference;
				$this->add_fields(call_user_func($field->reference.'::descriptor')->getFields(), $fieldData['ref']);
			}
			$fieldDatas[] = $fieldData;
		}
    }

    public function index() {
    	$data = [
    				"services" => $this->serviceDatas,
    				"json" => json_encode($this->serviceDatas)
    	        ];

    	$this->smarty->view('grpc.tpl', $data);  
    	//echo(json_encode());
    }

    public function call() {
        $address = $this->input->post("address");
        if ($address) {
            $this->grpc_host = $address;
        }
    	$service = $this->input->post("service");
    	$method = $this->input->post("method");
        $callcount = intval($this->input->post("callcount"));
    	$parameter = json_decode($this->input->post("parameter"),TRUE)[0];
    	$serviceMeta = new ReflectionClass($service); 
    	$parameterObj =  new $parameter["class"]();
    	foreach ($parameter["fields"] as $field) {
    		if (isset($field["class"])) {
    			$inner = new $field["class"]();
    			foreach ($field["ref"] as $innerField) {
    				$method_name = "set".ucfirst($innerField["name"]);
    				$inner->{$method_name}($innerField["value"]);
    			}
    			$method_name = "set".ucfirst($field["name"]);
    			$parameterObj->{$method_name}($inner);
    		}
    		else {
    			$method_name = "set".ucfirst($field["name"]);
    			$parameterObj->{$method_name}($field["value"]);
    		}
    	}
    	
        if ($callcount > 1) {
            for($i = 0; $i < $callcount; $i++) {
                $grpcService = new $service($this->grpc_host, [
                    'credentials' => Grpc\ChannelCredentials::createInsecure()
                ]);
                list($reply, $status) = $grpcService->{$method}($parameterObj)->wait();
            }
            $this->output->set_content_type('application/json', 'utf-8');
            $this->output->set_output(json_encode($reply));
        }
        else {
            $grpcService = new $service($this->grpc_host, [
                    'credentials' => Grpc\ChannelCredentials::createInsecure()
            ]);
            list($reply, $status) = $grpcService->{$method}($parameterObj)->wait();
            $this->output->set_content_type('application/json', 'utf-8');
            $this->output->set_output(json_encode($reply));
        }
		
		
		//echo json_encode($reply);
    	//var_dump($parameterObj);
    	
    }
}
