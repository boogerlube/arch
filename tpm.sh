#############################################################################
###           Be sure and update disk before running this script          ###
### Usual options are:                                                    ###
### /dev/gpt-auto-root-luks for DPS                                       ###
### /dev/sda2 for ProxMox                                                 ### 
### /dev/nvme0n1p2 for physical machines                                  ###
#############################################################################

disk="/dev/gpt-auto-root-luks"
TPM=true

if ! [ -e $disk ] ; then
   echo -e "\n\nDevice does not exist!"
   exit
fi

if ! [ -e /dev/tpmrm0 ] ; then
   echo -e "\n\nTPM 2.0 does not exist!"
   exit
fi   

echo -e "Recovery key for $(hostname) generated on $(date).\n" > $(hostname)-recovery.txt

sudo systemd-cryptenroll $disk --recovery-key | tee -a $(hostname)-recovery.txt
if $TPM ; then
  sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7  --tpm2-with-pin=yes $disk
else 
  sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 $disk
fi
echo -e "\n\n" >> $(hostname)-recovery.txt
