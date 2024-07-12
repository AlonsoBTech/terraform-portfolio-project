# terraform-portfolio-project


## 📋 <a name="table">Table of Contents</a>

1. 🤖 [Introduction](#introduction)
2. ⚙️ [Prerequisites](#prerequisites)
3. 🔋 [What Is Being Created](#what-is-being-created)
4. 🤸 [Quick Guide](#quick-guide)

5. ## <a name="introduction">🤖 Introduction</a>



![terraform portfolio project](https://github.com/user-attachments/assets/2ab9319c-f76a-4a53-aa0b-70440eab7682)


## <a name="prerequisites">⚙️ Prerequisites</a>

Make sure you have the following:

- AWS Account
- AWS IAM User
- Terraform Installed
- IDE of choice to write Terraform code

## <a name="what-is-being-created">🔋 What Is Being Created</a>

What we will be creating and using:

- Amazon S3 Bucket
- Amazon CloudFront
- DynamoDB

## <a name="quick-guide">🤸 Quick Guide</a>

Create a S3 bucket and DynamoDB table for Terraform state locking.

For the S3 bucket give it a name and leave all other defaults then click create.
S3 Bucket Creation:
![name tf s3](https://github.com/user-attachments/assets/f003ae42-62e6-468f-af2b-33dc00769501)

For the DynamoDB table, give it a name and set the partition key then click create while leaving all other defaults.
DynamoDB Creation:
![dynamodb creation](https://github.com/user-attachments/assets/344f8dcd-20cf-4954-964e-4e06a26b4372)

Create a terraform folder within your Node.js project folder.


```bash
mkdir terraform-js
```

Now create your terraform "state.tf" file which we will be using for having our state file store on AWS 
as our backend instead of having it stored locally.

</details>

<details>
<summary><code>state.tf</code></summary>

```bash
terraform {
  backend "s3" {
    bucket         = "aeb-blog-terraform-state"
    key            = "global/s3/terraform.state"
    region         = "ca-central-1"
    dynamodb_table = "aeb-blog-website-table"
  }
}
```
</details>
