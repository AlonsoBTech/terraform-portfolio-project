terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
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
        Name = "AEB-Blog Next.js Bucket"
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

    block_public_acls = false
    block_public_policy = false 
    ignore_public_acls = false
    restrict_public_buckets = false
}

# S3 Bucket ACLs
resource "aws_s3_bucket_acl" "nextjs_bucket_acl" {
    depends_on = [
        aws_s3_bucket_ownership_controls.nextjs_bucket_ownership,
        aws_s3_bucket_public_access_block.nextjs_public_access_block
    ]

    bucket = aws_s3_bucket.nextjs_bucket.id 
    acl = "public-read"
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
  bucket = aws_s3_bucket.example.id
  policy = jsoncode (({
    version = "2012-10-17"
    Statement = [
        {
            Sid = "PublicReadGetObject"
            Effect = "Allow"
            Principal = "*"
            Action = "s3:GetObject"
            Resource = "${aws_s3_bucket.nextjs_bucket.arn}/*"
        }
    ]
  }))
}
