# Terraform Portfolio Project


## 📋 <a name="table">Table of Contents</a>

1. 🤖 [Introduction](#introduction)
2. ⚙️ [Prerequisites](#prerequisites)
3. 🔋 [What Is Being Created](#what-is-being-created)
4. 🤸 [Quick Guide](#quick-guide)

5. ## <a name="introduction">🤖 Introduction</a>

This project focus on implementing a solution for deploying a Next.js website. The website deployment needs to be
scalable, cost-effective, highly available and delivers fast loading times for a global audience. Amazon S3 
will be our choice of hosting the website as it is cost-effective, scalable and also highly available. As for fast load
times and global reach, we will be using Amazon CloudFront for our content delivery network.

![terraform portfolio project](https://github.com/user-attachments/assets/8e5d368d-4194-408a-b108-719bf6849d1f)

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

Create a S3 bucket and DynamoDB table for Terraform state locking. For the S3 bucket give it a name 
and leave all other defaults then click create.

S3 Bucket Creation:

![name tf s3](https://github.com/user-attachments/assets/f003ae42-62e6-468f-af2b-33dc00769501)


For the DynamoDB table, give it a name and set the partition key then click create while leaving all other defaults.

DynamoDB Creation:

![dynamodb creation](https://github.com/user-attachments/assets/344f8dcd-20cf-4954-964e-4e06a26b4372)

Create a terraform folder within your Next.js project folder.

```bash
mkdir terraform-js
```

Now create your terraform "state.tf" file which we will be using for storing our state file on AWS 
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

Once the "state.tf" is done save it then create your "main.tf" file. This is where our main code will be located.
What we will be creating with our code for the "main.tf"
are:
- S3 Bucket
- Amazon CloudFront

For the S3 bucket we need to configure: 
- Bucket ownership
- Public access for the Next.js website
- ACL (Access Control List)
- Set the bucket policy
- Website configuration for our "index.hmtl".

</details>

<details>
<summary><code>S3 Bucket Configuration</code></summary>

```bash
# S3 Bucket
resource "aws_s3_bucket" "nextjs_bucket" {
  bucket = "aeb-blog-nextjs-bucket"

  tags = {
    Name        = "AEB-Blog Next.js Bucket"
    Environment = "Dev"
  }
}

# S3 Bucket Ownership
resource "aws_s3_bucket_ownership_controls" "nextjs_bucket_ownership" {
  bucket = aws_s3_bucket.nextjs_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "nextjs_public_access_block" {
  bucket = aws_s3_bucket.nextjs_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 Bucket ACLs
resource "aws_s3_bucket_acl" "nextjs_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.nextjs_bucket_ownership,
    aws_s3_bucket_public_access_block.nextjs_public_access_block
  ]

  bucket = aws_s3_bucket.nextjs_bucket.id
  acl    = "public-read"
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "nextjs_website_config" {
  bucket = aws_s3_bucket.nextjs_bucket.id
  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "nextjs_bucket_policy" {
  bucket = aws_s3_bucket.nextjs_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.nextjs_bucket.arn}/*"
      }
    ]
  })
}
```
</details>


Now we need to create our CloudFront distribution. The CloudFront distribution will need an origing access
identity. We need to configure the CloudFront:
- Viewer protocol policy
- Cache behavior
- Geolocation restrictions
- Setting the S3 domain name as cloudfront orirgin


</details>

<details>
<summary><code>CloudFront Distribution Configuration</code></summary>

```bash
# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "cdn_origin_access_identity" {
  comment = "Origin Access Identity for Next.js portfolio website"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "nextjs_cloudfront_distribution" {
  origin {
    domain_name = aws_s3_bucket.nextjs_bucket.bucket_regional_domain_name
    origin_id   = "s3-nextjs-portfolio-bucket"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cdn_origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "AEB-Blog Next.js portfolio site"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-nextjs-portfolio-bucket"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
```
</details>


This is what the "main.tf" file looks like once everything is configured:

</details>

<details>
<summary><code>main.tf</code></summary>

```bash
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.57.0"
    }
  }
}

provider "aws" {
  region = "ca-central-1"
}

# S3 Bucket
resource "aws_s3_bucket" "nextjs_bucket" {
  bucket = "aeb-blog-nextjs-bucket"

  tags = {
    Name        = "AEB-Blog Next.js Bucket"
    Environment = "Dev"
  }
}

# S3 Bucket Ownership
resource "aws_s3_bucket_ownership_controls" "nextjs_bucket_ownership" {
  bucket = aws_s3_bucket.nextjs_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "nextjs_public_access_block" {
  bucket = aws_s3_bucket.nextjs_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 Bucket ACLs
resource "aws_s3_bucket_acl" "nextjs_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.nextjs_bucket_ownership,
    aws_s3_bucket_public_access_block.nextjs_public_access_block
  ]

  bucket = aws_s3_bucket.nextjs_bucket.id
  acl    = "public-read"
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "nextjs_website_config" {
  bucket = aws_s3_bucket.nextjs_bucket.id
  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "nextjs_bucket_policy" {
  bucket = aws_s3_bucket.nextjs_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.nextjs_bucket.arn}/*"
      }
    ]
  })
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "cdn_origin_access_identity" {
  comment = "Origin Access Identity for Next.js portfolio website"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "nextjs_cloudfront_distribution" {
  origin {
    domain_name = aws_s3_bucket.nextjs_bucket.bucket_regional_domain_name
    origin_id   = "s3-nextjs-portfolio-bucket"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cdn_origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "AEB-Blog Next.js portfolio site"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-nextjs-portfolio-bucket"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
```
</details>


Save the file and run "terraform init" to initialize the configuration files.

```bash
terraform init
```

![image](https://github.com/user-attachments/assets/fad07350-e182-4f16-ba37-fd061b0e0fa1)


Run "terraform plan" to see what is being deployed.

```bash
terraform plan
```

![image](https://github.com/user-attachments/assets/53096565-72e2-4e77-b434-74a68f8a20c6)


Run "terraform apply" to deploy the infrastructure, type "Yes" to agree when prompted.

```bash
terraform apply
```

![image](https://github.com/user-attachments/assets/afba68a5-2369-4ac4-8de7-3950d4d1ee9c)


Switch to the "out" folder of your Next.js project and upload the files to the S3 bucket.

![image](https://github.com/user-attachments/assets/c4d824f2-f338-4b55-b4dd-119065e7a7ea)


Run "terraform show" to view the CloudFront domain name and copy it.

```bash
terraform show
```

![terraform show](https://github.com/user-attachments/assets/cd37d95f-35c0-4b15-8c7d-b47c6257e989)


Now paste the CloudFront domain name in the web browser to access your Next.js website.

![image](https://github.com/user-attachments/assets/c190ebf0-a68e-4f23-8dfb-13db4cf5f231)



