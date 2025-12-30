# Thanks to MrPowerGamerBR (https://github.com/MrPowerGamerBR)

#!/bin/bash
GENERATED_UUID=$(uuidgen)
echo -n $GENERATED_UUID | wl-copy
kdialog --passivepopup "UUID generated!\n$GENERATED_UUID"