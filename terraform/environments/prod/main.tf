# 1. PayGuard 프로젝트용 SSH 키 페어 생성
resource "cloudstack_ssh_keypair" "payguard_key" {
  name = "payguard-public-key"
}

# 2. 생성된 키의 이름 화면에 출력
output "ssh_key_name" {
  value       = cloudstack_ssh_keypair.payguard_key.name
  description = "생성된 SSH 키 페어의 이름"
}

# 3. 생성된 프라이빗 키값 출력 
output "ssh_private_key" {
  value       = cloudstack_ssh_keypair.payguard_key.private_key
  description = "생성된 SSH 프라이빗 키 (절대 노출 금지!)"
  sensitive   = true
}