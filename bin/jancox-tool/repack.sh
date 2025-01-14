#!/system/bin/sh
#Jancox-Tool-Android
#by wahyu6070


#PATH
jancox=`dirname "$(readlink -f $0)"`
#functions
. $jancox/bin/arm/kopi
#bin
bin=$jancox/bin/$ARCH32
bb=$bin/busybox
tmp=$jancox/bin/tmp
pybin=$jancox/bin/python
editor=$jancox/editor
profile=$jancox/bin/jancox.prop
log=$jancox/bin/jancox.log
loglive=$jancox/bin/jancox.live.log
chmod -R 755 $bin

clear
[ $(pwd) != $jancox ] && cd $jancox
del $loglive && touch $loglive
if [ ! -d $editor/system ]; then printlog "     Please Unpack !!"; exit; fi
mkdir -p $tmp
mkdir -p $editor
if [ -f /data/data/com.termux/files/usr/bin/python ]; then
py=/data/data/com.termux/files/usr/bin/python
else
printlog " "
printlog "- python 3 Not Installed In Termux !"
printlog " "
printlog "- apt update"
printlog "- apt upgrade"
printlog "- pkg install python"
printlog " "
sleep 1s
exit
fi
printmid "${Y}Jancox Tool by wahyu6070${W}"
printlog "       Repack "
printlog " "
rom-info $editor
printlog " "
[ ! -d $tmp ] && mkdir $tmp

if [[ $(getp set.time $profile) == true ]]; then
setime -r $editor/product $(getp setime.date)
setime -r $editor/system $(getp setime.date)
setime -r $editor/vendor $(getp setime.date)
fi

if [ -d $editor/product ]; then
printlog "-Repack product"
size1=`$bb du -sk $editor/product | $bb awk '{$1*=1024;$1=int($1*1.05);printf $1}'`
$bin/make_ext4fs -s -L product -T 2009110000 -S $editor/product_file_contexts -C $editor/product_fs_config -l $size1 -aproduct $rtmp/product.img $editor/product/ > $loglive
sedlog "product size = $size1"
fi

if [ -d $editor/system ]; then
printlog "- Repack system"
size2=`$bb du -sk $editor/system | $bb awk '{$1*=1024;$1=int($1*1.05);printf $1}'`
$bin/make_ext4fs -s -L system -T 2009110000 -S $editor/system_file_contexts -C $editor/system_fs_config -l $size2 -a system $tmp/system.img $editor/system/ > $loglive
sedlog "system size = $size2"
fi

if [ -d $editor/vendor ]; then
printlog "- Repack vendor"
size3=`$bb du -sk $editor/vendor | $bb awk '{$1*=1024;$1=int($1*1.05);printf $1}'`
$bin/make_ext4fs -s -L vendor -T 2009110000 -S $editor/vendor_file_contexts -C $editor/vendor_fs_config -l $size3 -a vendor $tmp/vendor.img $editor/vendor/ > $loglive
fi

if [ -f $tmp/product.img ] && [ $(getp compress.dat $profile) = true ]; then
printlog "- Repack product.img"
[ -f $tmp/product.new.dat ] && rm -rf $tmp/product.new.dat
$py $pybin/img2sdat.py $tmp/system.img -o $tmp -v 4 -p product >> $loglive
[ -f $tmp/product.img ] && rm -rf $tmp/product.img
fi

if [ -f $tmp/system.img ] && [ $(getp compress.dat $profile) = true ]; then
printlog "- Repack system.img"
[ -f $tmp/system.new.dat ] && rm -rf $tmp/system.new.dat
$py $pybin/img2sdat.py $tmp/system.img -o $tmp -v 4 >> $loglive
[ -f $tmp/system.img ] && rm -rf $tmp/system.img
fi

if [ -f $tmp/vendor.img ] && [ $(getp compress.dat $profile) = true ]; then
printlog "- Repack vendor.img"
[ -f $tmp/vendor.new.dat ] && rm -rf $tmp/vendor.new.dat
$py $pybin/img2sdat.py $tmp/vendor.img -o $tmp -v 4 -p vendor >> $loglive
[ -f $tmp/vendor.img ] && rm -rf $tmp/vendor.img
fi

#level brotli
case $(getp brotli.level $jancox/bin/jancox.prop) in
1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 ) brlvl=`getp brotli.level $jancox/bin/jancox.prop` ;;
*) brlvl=1 ;;
esac
sedlog "- Brotli level : $brlvl"
if [ -f $tmp/product.new.dat ]; then
printlog "- Repack product.new.dat"
[ -f $tmp/product.new.dat.br ] && rm -rf $tmp/product.new.dat.br
$bin/brotli -$brlvl -j -w 24 $tmp/product.new.dat >> $loglive
fi

if [ -f $tmp/system.new.dat ]; then
printlog "- Repack system.new.dat"
[ -f $tmp/system.new.dat.br ] && rm -rf $tmp/system.new.dat.br
$bin/brotli -$brlvl -j -w 24 $tmp/system.new.dat >> $loglive
fi

if [ -f $tmp/vendor.new.dat ]; then
[ -f $tmp/vendor.new.dat.br ] && rm -rf $tmp/vendor.new.dat.br
printlog "- Repack vendor.new.dat"
$bin/brotli -$brlvl -j -w 24 $tmp/vendor.new.dat >> $loglive
fi

if [ -d $editor/boot ] && [ -f $editor/boot/boot.img ]; then
printlog "- Repack boot"
for BOOT_FILES in kernel kernel_dtb ramdisk.cpio second; do
[ -f $editor/boot/$BOOT_FILES ] && cp -f $editor/boot/$BOOT_FILES $jancox
sedlog "- Moving boot file $editor/boot/$BOOT_FILES to $jancox"
done
$bin/magiskboot repack $editor/boot/boot.img 2>> $loglive
sleep 1s
[ -f $jancox/new-boot.img ] && mv -f $jancox/new-boot.img $tmp/boot.img
for RM_BOOT_FILES in kernel kernel_dtb ramdisk.cpio second; do
test -f $jancox/$RM_BOOT_FILES && rm -rf $jancox/$RM_BOOT_FILES
sedlog "- Removing boot file $janxoz$RM_BOOT_FILES"
done
fi

[ -d $editor/META-INF ] && cp -a $editor/META-INF $tmp/
[ -d $editor/install ] && cp -a $editor/install $tmp/
[ -d $editor/system2 ] && cp -a $editor/system2 $tmp/system
[ -d $editor/firmware-update ] && cp -a $editor/firmware-update $tmp/
[ -f $editor/compatibility.zip ] && cp -f $editor/compatibility.zip $tmp/
[ -f $editor/compatibility_no_nfc.zip ] && cp -f $editor/compatibility_no_nfc.zip $tmp/

if [ -d $tmp/META-INF ] && [ $(getp zipping $profile) = true ]; then
printlog "- Zipping"
ZIPNAME=`echo "new-rom_$(date +%Y-%m-%d)"`
[ $(getp zip.level $jancox/bin/jancox.prop) -le 9 ] && ZIPLEVEL=`getp zip.level $jancox/bin/jancox.prop` || ZIPLEVEL=1
[ -f ${ZIPNAME}.zip ] && del ${ZIPNAME}.zip
cd $tmp
$bin/zip -r${ZIPLEVEL} $jancox/"${ZIPNAME}.zip" . >> $loglive || sedlog "Failed creating $jancox/${zipname}.zip"
sedlog "ZIP NAME  : ${ZIPNAME}.zip"
sedlog "ZIP LEVEL : ${ZIPLEVEL}"
cd $jancox
fi


if [ -f "${ZIPNAME}.zip" ]; then
      printlog "- Repack done"
      del $tmp
else
      printlog "- Repack error"
      del $tmp
fi

clog

