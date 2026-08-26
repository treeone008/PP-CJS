terraform {
  required_version = ">= 1.0.0"

  required_providers {
    cloudstack = {
      source  = "cloudstack/cloudstack"
      version = "0.4.0"
    }
  }
}

provider "cloudstack" {
  # kt cloud의 API 엔드포인트 (사용하시는 존(Zone)에 따라 달라질 수 있습니다)
  # 예: 천안/목동 등 G1/G2 존 API 주소
  api_url    = var.ktcloud_api_url
  api_key    = var.ktcloud_api_key
  secret_key = var.ktcloud_secret_key
}