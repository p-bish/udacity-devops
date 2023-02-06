module "tag-policy" {
  source = "./modules/tag-policy"
}
module "webvmproject" {
  source = "./modules/web-server"
  IMAGE_NAME = var.IMAGE_NAME
  IMAGE_RG = var.IMAGE_RG
  CREATOR = var.CREATOR
  VMCOUNT = var.VMCOUNT
  ADMIN_PASS = var.ADMIN_PASS
  RGNAME = var.RGNAME
}