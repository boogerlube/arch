sudo systemd-cryptenroll /dev/gpt-auto-root-luks --recovery-key
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7  --tpm2-with-pin=yes /dev/gpt-auto-root-luks