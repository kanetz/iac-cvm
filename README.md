iac-cvm
====

使用 [Terraform](https://developer.hashicorp.com/terraform/downloads) 创建一个测试用途的 [腾讯云 CVM](https://cloud.tencent.com/product/cvm) 实例。

- 配置并提供以下用于调用腾讯云API的环境变量：
    - `export TENCENTCLOUD_SECRET_ID="<my-secret-id>"`
    - `export TENCENTCLOUD_SECRET_KEY="<my-secret-key>"`
    - `export TENCENTCLOUD_REGION="ap-guangzhou"`

- 初始化 Terraform 模块：`terraform init`

- 创建腾讯云资源：`terraform apply`

- 删除腾讯云资源：`terraform destroy`
