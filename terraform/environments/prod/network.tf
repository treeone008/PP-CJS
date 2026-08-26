# 1. 사용할 Zone 이름 변수
variable "ktcloud_zone_name" {
  description = "사용 중인 kt cloud Zone 이름"
  type        = string
}

# 2. VPC 없이 Private Subnet 단독 생성
resource "cloudstack_network" "payguard_app_tier" {
  name             = "payguard-app-tier"
  display_text     = "PayGuard App Subnet for K8s"
  cidr             = "10.0.1.0/24"
  # CloudStack 및 kt cloud의 기본 격리 네트워크(Private Subnet) 상품명
  network_offering = "DefaultIsolatedNetworkOfferingWithSourceNatService" 
  zone             = var.ktcloud_zone_name
}