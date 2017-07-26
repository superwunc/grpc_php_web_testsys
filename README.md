# grpc_php_web_testsys
基于grpc php 文件 自动生成所有API接口的测试界面，以JSON格式显示GRPC 调用结果
核心文件
website\application\controllers\Grpc.php

读取 website\application\proto\ 下所有grpc php 客户端代码，通过反射机制，获取所有类，以及方法

方法 call ,获取前端提交参数，封装grpc 参数，请求grpc 服务器端，返回结果 转为JSON，返回前端展现

依赖
"require": {
		"grpc/grpc": "^1.0",
		"rmccue/requests": ">=1.0"
}

需要安装 grpc 扩展

extension=grpc.so
extension=protobuf.so



