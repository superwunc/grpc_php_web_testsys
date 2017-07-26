<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>GRPC API 列表</title>
  <link rel="stylesheet" href="/resources/libs/semantic/semantic.css" />
  <link rel="stylesheet" href="/resources/libs/jquery.jsonview.min.css" />
  <script type="text/javascript" src="/resources/libs/jquery-2.2.0.min.js"></script>
  <script type="text/javascript" src="/resources/libs/qwest.min.js"></script>
  <script type="text/javascript" src="/resources/libs/semantic/semantic.js"></script>
  <script type="text/javascript" src="/resources/libs/jquery.jsonview.min.js"></script>

  <style type="text/css">
    .content {
      padding-left: 10px;
    }
    #json {
      height: 400px;
      overflow-y: auto;
    }

    .html.segment {
      padding: 3.5em 1em 1em;
      margin-bottom: 10px !important;
    }

    #content_body {
      padding: 10px;
    }
  </style>
</head>
<body id="content_body">
<div class="html ui top attached segment">
<form class="ui form" >
  <div class="field">
    <label>自定义环境</label>
    <input type="text" id="address"/>
  </div>
  <div class="field">
   <label>开发环境</label>
    <select class="ui fluid dropdown" id="address_select">
    <option value="10.32.186.20:6565">测试环境10.32.186.20:6565</option>
<!--    <option value="10.32.186.11:6565">测试环境10.32.186.11:6565</option> -->
    <option value="app.i-dalian.cn:56565">正式环境app.i-dalian.cn:56565</option>
    </select>
  </div>
 
</form>
<div class="ui top attached label">环境设置</i></div>
</div>
<div class="html ui top attached segment">
<div class="ui styled fluid accordion">
 {%foreach $services as $service %}
  <div class="title" >
    <i class="dropdown icon"></i>
      {%$service["title"]%}
  </div>
  <div class="content">
    <div class="ui styled fluid ">
        {%foreach $service["methods"] as $method %}
        <div class="title" >
            <i class="dropdown icon"></i>
              {%$method["name"]%}
        </div>
        <div class="content" data-method="{%$method['name']%}" data-service="{%$service['name']%}">
        {%foreach $method["parameters"] as $parameter %}
         <table class="ui celled table" style="width: 100%;">
            <thead> 
             <tr>
               {%foreach $parameter["fields"] as $field %}
                <th>{%$field["name"]%}</th>
               {%/foreach%}
             </tr>
            </thead>
             <tbody> 
             <tr>
                {%foreach $parameter["fields"] as $field %}
                {%if isset($field['ref']) %}
                 <td>
                    <table class="ui celled table" style="width: 100%;">
                        <thead> 
                         <tr>
                           {%foreach $field['ref'] as $reffield %}
                            <th>{%$reffield["name"]%}</th>
                           {%/foreach%}
                         </tr>
                        </thead>
                         <tbody> 
                         <tr>
                            {%foreach $field['ref'] as $reffield %}
                            <td><input style="width:40px;" data-parameter="{%$field['name']%}.{%$reffield['name']%}"/></td>
                            {%/foreach%}
                         </tr>
                         </tbody>
                    </table>
                    </td>
                {%else%}
                    <td><input  data-parameter="{%$field['name']%}"/></td>
                {%/if%}
                {%/foreach%}
             </tr>
            </tbody>
         </table>
         {%/foreach%}
        <label>调用次数</label><input id="{%$service['name']%}_{%$method["name"]%}_count"  value="0"/>
        <button class="ui primary button" onclick="exeTest(event)">测试</button>
        </div>
      {%/foreach%}
    </div>
  </div>
 {%/foreach%}
</div>
<div class="ui top attached label">城事汇 Grpc Services 列表</div>
</div>
<div class="ui modal">
  <i class="close icon"></i>
  <div class="header">
    服务器返回结果
  </div>
  <div class="content">
      <div id="json"></div>
  </div>
  <div class="actions">
    <div class="ui black deny button">
      保存
    </div>
  </div>
</div>
<script type="text/javascript">
  
  var SERVICE_DATA = {%$json%};
  function getServiceMethod(serviceName, methodName) {
      var service = null;
      var methods = null;
      var method = null;
      for (var i = 0, l = SERVICE_DATA.length; i < l; i++) {
          service = SERVICE_DATA[i];
          if (service["name"] == serviceName) {
              methods = service["methods"];
              for (var m = 0, n = methods.length; m < n; m++) {
                  method = methods[m];
                  if (method["name"] == methodName) {
                      return method;
                  }
              }
          }
      }
      return null;
  }
</script>
 <script type="text/javascript">
  function getDataValue(element, name) {
      while(element) {
        if (element && element.hasAttribute && element.hasAttribute(name)) {
          return element.getAttribute(name);
        }
        element = element.parentNode;
      }
      return null;
  }

  function getDataElement(element, name) {
      while(element) {
        if (element && element.hasAttribute && element.hasAttribute(name)) {
          return element;
        }
        element = element.parentNode;
      }
      return null;
  }


  function getMethodParameterValue(methodElement, parameterName) {
      var inputs = methodElement.getElementsByTagName("input");
      var input = null;
      var name = null;
      for (var i = 0, l = inputs.length; i < l; i++) {
          input = inputs[i];
          name = input.getAttribute("data-parameter");
          if (name == parameterName) {
              return input.value;
          }
      }
      return null;
  }



  function exeTest(event) {
      var srcElement = event.srcElement;
      var serviceName = getDataValue(srcElement, "data-service");
      var methodName = getDataValue(srcElement, "data-method");
      var method = getServiceMethod(serviceName, methodName);
      var methodElement = getDataElement(srcElement, "data-method");
      var methodCallCount = parseInt(document.getElementById(serviceName + "_" +  methodName + "_count").value);

      var parameter = null;
      var fields = null;
      for(var i = 0, l = method.parameters.length; i < l; i++) {
          parameter = method.parameters[i];
          fields = parameter.fields;
          for (var m = 0, n = fields.length; m < n; m++) {
              if (fields[m].ref) {
                  for (var x = 0, y = fields[m].ref.length; x < y; x++) {
                      fields[m].ref[x]["value"] = getMethodParameterValue(methodElement, fields[m]["name"]+ "." + fields[m].ref[x]["name"]);
                  }
              }
              else {
                  fields[m]["value"] = getMethodParameterValue(methodElement, fields[m]["name"]);
              }
          }
      }

      /*
      
      var parameter = {};
      var inputs = methodElement.getElementsByTagName("input");
      var name = null;
      var input = null;
      for (var i = 0, l = inputs.length; i < l; i++) {
          input = inputs[i];
          name = input.getAttribute("data-parameter");
          if (name) {
              if (name.indexOf(".") > 0) {
                  var namespace = name.split(".");
                  if (!parameter[namespace[0]]) {
                      parameter[namespace[0]] = {};
                  }
                  parameter[namespace[0]][namespace[1]] = input.value;
              }
              else {
                  parameter[name] = input.value;
              }
          }
      }
     
      */
      var data = {
        "service": serviceName,
        "method": methodName,
        "callcount": methodCallCount,
        "parameter": JSON.stringify(method.parameters)
      };
      var address = document.getElementById("address").value;
      if (address && address.length > 0) {
          data["address"] = address;
      }
      else {
          address = document.getElementById("address_select").value;
          data["address"] = address;
      }
      qwest.post('/index.php/grpc/call', data, {responseType:"json"})
        .then(function(xhr, response) {
            $("#json").JSONView(response, { collapsed: true });
            $('.ui.modal').modal('show');
        });
  }
   $('.ui.accordion').accordion();
 </script>
</body>
</html>