### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
properties() { '
kernel.string=5.4.302-Feather | SukiSU Ultra + SusFS v2.2.0 | @ozyern
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=lemonade
device.name2=lemonadep
device.name3=lemonades
device.name4=lemonadev
device.name5=OnePlus9
device.name6=OnePlus9Pro
device.name7=OnePlus 9
device.name8=OnePlus 9 Pro
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties

### AnyKernel install

## stage 1 -- boot: kernel only (this partition has no dtb on lahaina)
BLOCK=boot;
IS_SLOT_DEVICE=1;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

. tools/ak3-core.sh;

ui_print " ";
ui_print "Installing 5.4.302-Feather kernel to boot...";
dump_boot;
write_boot;

## stage 2 -- vendor_boot: install the matching device tree
## The lahaina dtb lives in vendor_boot, not boot. A 5.4.302 kernel paired
## with the stock 5.4.254 dtb is what bootlooped at the splash, so the dtb
## built from this same tree has to go with it.
## flash_boot prefers $AKHOME/dtb over split_img/dtb, so shipping ./dtb is
## enough -- it is ignored in stage 1 because boot has no dtb to replace.
BLOCK=vendor_boot;
IS_SLOT_DEVICE=1;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

rm -f $AKHOME/Image;

reset_ak;

ui_print " ";
ui_print "Installing Feather device tree to vendor_boot...";
dump_boot;
write_boot;

ui_print " ";
ui_print "-----------------------------------------";
ui_print "  Feather Kernel 5.4.302";
ui_print "  SukiSU Ultra 4.1.3 | SusFS v2.2.0";
ui_print "  kernel -> boot";
ui_print "  dtb    -> vendor_boot";
ui_print "  dtbo   -> dtbo";
ui_print "-----------------------------------------";
ui_print " ";
