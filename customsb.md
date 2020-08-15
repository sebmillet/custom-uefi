Title: Customize Secure Boot
Date: 2020-06-19
Authors: Sébastien Millet
Category: TI

1. Goal
-------

The goal is to have you own certificate in the Secure Boot *db* variable.

Then, to sign Linux with your own certificate.

As we have dual boot with Windows, we'll keep Microsoft and PC manufacturer
certificates.

   * Pre-requisites

     Under Arch Linux, install the packages *efitools* and *sbsigntool*.

If you want to see the abstract of commands to execute, go to
[8. Abstract of commands](#abstract-of-commands)

***

2. Enter *Setup Mode* and rewrite PK
------------------------------------

On my Acer Swift3, I have to do the following:

   - Find *KeyTool.efi*. On Arch Linux, it is found in *efitools* package.

   - Initialize a USB key with an ESP (*EFI System Partition*) and copy
     KeyTool.efi on the USB key with the name
     `{USBROOT}\EFI\BOOT\bootx64.efi`

   - Write PK.auth (see below) on the USB key.

   - Launch KeyTool upon PC start (that is, `{USBROOT}\EFI\BOOT\bootx64.efi`),
     and in KeyTool interface, update PK with the file PK.auth.

     When in KeyTool interface, be sure you are in *Setup Mode*. It is displayed
     in the first screen of KeyTool.

The above works for a 64-bit Intel architecture.

### 2.1 Backup current keys

It'll be needed later in this document.

<pre><code>    <b><span style="color: #0000a0">mkdir svgkeys</span></b>
    <b><span style="color: #0000a0">cd svgkeys/</span></b>
    <b><span style="color: #0000a0">efi-readvar -v PK -o svgPK.esl</span></b>
    Variable PK, length 955
    <b><span style="color: #0000a0">efi-readvar -v KEK -o svgKEK.esl</span></b>
    Variable KEK, length 2519
    <b><span style="color: #0000a0">efi-readvar -v db -o svgdb.esl</span></b>
    Variable db, length 4995
    <b><span style="color: #0000a0">efi-readvar -v dbx -o svgdbx.esl</span></b>
    Variable dbx, length 4685
    <b><span style="color: #0000a0">ls -l</span></b>
    total 24
    -rw------- 1 sebastien sebastien 4995  1 juin  15:35 svgdb.esl
    -rw------- 1 sebastien sebastien 4685  1 juin  15:35 svgdbx.esl
    -rw------- 1 sebastien sebastien 2519  1 juin  15:35 svgKEK.esl
    -rw------- 1 sebastien sebastien  955  1 juin  15:35 svgPK.esl
</code></pre>

### 2.2. Commands execution

The below assumes the USB key is accessible as */dev/sda*:
<pre><code>    <b><span style="color: #b00000"># Commands executed as a regular user</span></b>
     
    <b><span style="color: #0000a0">mkdir uefi</span></b>
    <b><span style="color: #0000a0">cd uefi</span></b>
    <b><span style="color: #0000a0">uuidgen > GUID.txt</span></b>
    <b><span style="color: #0000a0">openssl req -utf8 -newkey rsa:4096 -keyout PK.key -new -x509 -sha256 -days 3650 -subj "/CN=SMT PK/" -out PK.crt</span></b>
    Generating a RSA private key
    .....++++
    ..............++++
    writing new private key to 'PK.key'
    Enter PEM pass phrase:
    Verifying - Enter PEM pass phrase:
    -----
    <b><span style="color: #0000a0">ls -l</span></b>
    total 12
    -rw-r--r-- 1 sebastien sebastien   37  1 juin  11:55 GUID.txt
    -rw-r--r-- 1 sebastien sebastien 1797  1 juin  11:55 PK.crt
    -rw------- 1 sebastien sebastien 3414  1 juin  11:55 PK.key
    <b><span style="color: #0000a0">cert-to-efi-sig-list -g $(< GUID.txt) PK.crt PK.esl</span></b>
    <b><span style="color: #0000a0">sign-efi-sig-list -g $(< GUID.txt) -c PK.crt -k PK.key PK PK.esl PK.auth</span></b>
    Timestamp is 2020-6-1 11:56:11
    Authentication Payload size 1371
    Enter PEM pass phrase:
    Signature of size 1928
    Signature at: 40
    <b><span style="color: #0000a0">ls -l</span></b>
    total 20
    -rw-r--r-- 1 sebastien sebastien   37  1 juin  11:55 GUID.txt
    -rw------- 1 sebastien sebastien 3299  1 juin  11:56 PK.auth
    -rw-r--r-- 1 sebastien sebastien 1797  1 juin  11:55 PK.crt
    -rw-r--r-- 1 sebastien sebastien 1331  1 juin  11:55 PK.esl
    -rw------- 1 sebastien sebastien 3414  1 juin  11:55 PK.key
     
    // PK.crt is PK certificate file, in PEM format
    // PK.key is PK certificate private key. I like to protect it with a password, if
    //        you you don't want a password, add -nodes option to openssl command.
    // PK.esl is PK.crt in the "EFI Signature List" format
    // PK.auth is PK.esl + signature done with PK.key
     
    <b><span style="color: #0000a0">sudo su -</span></b>
     
    <b><span style="color: #b00000"># Commands executed as root</span></b>
     
    <b><span style="color: #0000a0">cd /mnt</span></b>
    <b><span style="color: #0000a0">fdisk /dev/sda</span></b>
     
    Welcome to fdisk (util-linux 2.35.2).
    Changes will remain in memory only, until you decide to write them.
    Be careful before using the write command.
     
    Device does not contain a recognized partition table.
    Created a new DOS disklabel with disk identifier 0xcbd7aa8a.
     
    Command (m for help): <b><span style="color: #0000a0">g</span></b>
    Created a new GPT disklabel (GUID: B6DDF853-8C3B-D344-B1CC-66292334F64A).
     
    Command (m for help): <b><span style="color: #0000a0">n</span></b>
    Partition number (1-128, default 1):
    First sector (2048-15728606, default 2048):
    Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-15728606, default 15728606): <b><span style="color: #0000a0">+500M</span></b>
     
    Created a new partition 1 of type 'Linux filesystem' and of size 500 MiB.
     
    Command (m for help): <b><span style="color: #0000a0">t</span></b>
    Selected partition 1
    Partition type (type L to list all types): <b><span style="color: #0000a0">1</span></b>
    Changed type of partition 'Linux filesystem' to 'EFI System'.
     
    Command (m for help): <b><span style="color: #0000a0">w</span></b>
    The partition table has been altered.
    Calling ioctl() to re-read partition table.
    Syncing disks.
     
    <b><span style="color: #0000a0">fdisk -l /dev/sda</span></b>
    Disk /dev/sda: 7.51 GiB, 8053063680 bytes, 15728640 sectors
    Disk model: Flash Disk
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: gpt
    Disk identifier: B6DDF853-8C3B-D344-B1CC-66292334F64A
     
    Device     Start     End Sectors  Size Type
    /dev/sda1   2048 1026047 1024000  500M EFI System
    <b><span style="color: #0000a0">mkfs.vfat /dev/sda1 -F 32 -n "USBKEYTOOL"</span></b>
    mkfs.fat 4.1 (2017-01-24)
    <b><span style="color: #0000a0">mkdir usb</span></b>
    <b><span style="color: #0000a0">mount /dev/sda1 usb</span></b>
    <b><span style="color: #0000a0">cd usb</span></b>
    <b><span style="color: #0000a0">mkdir EFI</span></b>
    <b><span style="color: #0000a0">cd EFI</span></b>
    <b><span style="color: #0000a0">mkdir BOOT</span></b>
    <b><span style="color: #0000a0">cd BOOT</span></b>
    <b><span style="color: #0000a0">cp -i /usr/share/efitools/efi/KeyTool.efi bootx64.efi</span></b>
    <b><span style="color: #0000a0">cd ../..</span></b>
    <b><span style="color: #0000a0">cp -i ~sebastien/uefi/PK.auth .</span></b>
    <b><span style="color: #0000a0">cd ..</span></b>
    <b><span style="color: #0000a0">ls -lR usb</span></b>
    usb:
    total 8
    drwxr-xr-x 3 root root 4096  1 juin  12:01 EFI
    -rwxr-xr-x 1 root root 3299  1 juin  12:02 PK.auth
     
    usb/EFI:
    total 4
    drwxr-xr-x 2 root root 4096  1 juin  12:02 BOOT
     
    usb/EFI/BOOT:
    total 136
    -rwxr-xr-x 1 root root 136192  1 juin  12:02 bootx64.efi
    <b><span style="color: #0000a0">umount usb</span></b>
</code></pre>

### 2.3. Check result

Display PK variable:
<pre><code>    <b><span style="color: #0000a0">efi-readvar -v PK</span></b>
    Variable PK, length 1331
    PK: List 0, type X509
        Signature 0, size 1303, owner 68b8e83c-3fc1-4070-99be-d862b3531421
            Subject:
                CN=SMT PK
            Issuer:
                CN=SMT PK
</code></pre>

Note that I did numerous tests during which I'd recreate PK key many times. How
to make sure the certificate in PK is the one you expect?

You can use this script [fpcer.sh](fpcer.sh) that'll prints out a certificate
file fingerprint, and this script [fpvar.sh](fpvar.sh) to display a Secure Boot
variable certificates fingerprints.

Execution:
<pre><code>    <b><span style="color: #0000a0">./fpcer.sh PK.crt</span></b>
    66:51:E4:52:90:C8:77:3D:8A:5B:8C:26:95:08:51:53:EA:69:7D:E9 [SMT PK]
    <b><span style="color: #0000a0">./fpvar.sh PK</span></b>
    66:51:E4:52:90:C8:77:3D:8A:5B:8C:26:95:08:51:53:EA:69:7D:E9 [SMT PK]
</code></pre>

### 2.4 Alternate method

The methode above is the most robust, all you need is to be able to start the
computer on a USB key that contains KeyTool.efi and the new PK file (PK.auth),
while being in *Setup Mode*.

If you can enter *Setup Mode* and start your installed Linux system, a simpler way
is to write the new PK from Linux.

Entering *Setup Mode* normally requires to wipe PK. On my Acer Swift3, to do so
I have to wipe *all* Secure Boot variables (*PK*, *KEK*, *db* and *dbx*).

Assuming you are in *Setup Mode* and have obtained PK key files as shown
earlier, do the below:
<pre><code>    <b><span style="color: #0000a0">ls -l</span></b>
    total 20
    -rw-r--r-- 1 sebastien sebastien   37  1 juin  11:55 GUID.txt
    -rw------- 1 sebastien sebastien 3299  1 juin  11:56 PK.auth
    -rw-r--r-- 1 sebastien sebastien 1797  1 juin  11:55 PK.crt
    -rw-r--r-- 1 sebastien sebastien 1331  1 juin  11:55 PK.esl
    -rw------- 1 sebastien sebastien 3414  1 juin  11:55 PK.key
    <b><span style="color: #0000a0">efi-readvar -v PK</span></b>
    Variable PK has no entries
    <b><span style="color: #0000a0">sudo efi-updatevar -f PK.auth PK</span></b>
    <b><span style="color: #0000a0">efi-readvar -v PK</span></b>
    Variable PK, length 1331
    PK: List 0, type X509
        Signature 0, size 1303, owner 68b8e83c-3fc1-4070-99be-d862b3531421
            Subject:
                CN=SMT PK
            Issuer:
                CN=SMT PK
</code></pre>

***

3. Add your certificate to KEK
------------------------------

We now own PK, that'll allow us to update KEK and from there, update db.

We'll also set dbx to its former value (before wipe).

The goal here is to add our certificate to KEK, keeping existing certificates.
This is why we had to backup current variables into *~/svgkeys* before wiping
variables.

Execute:
<pre><code>    <b><span style="color: #0000a0">ls -l</span></b>
    total 20
    -rw-r--r-- 1 sebastien sebastien   37  1 juin  11:55 GUID.txt
    -rw------- 1 sebastien sebastien 3299  1 juin  11:56 PK.auth
    -rw-r--r-- 1 sebastien sebastien 1797  1 juin  11:55 PK.crt
    -rw-r--r-- 1 sebastien sebastien 1331  1 juin  11:55 PK.esl
    -rw------- 1 sebastien sebastien 3414  1 juin  11:55 PK.key
    <b><span style="color: #0000a0">openssl req -utf8 -newkey rsa:4096 -keyout KEK.key -new -x509 -sha256 -days 3650 -subj "/CN=SMT KEK/" -out KEK.crt</span></b>
    Generating a RSA private key
    ............++++
    .++++
    writing new private key to 'KEK.key'
    Enter PEM pass phrase:
    Verifying - Enter PEM pass phrase:
    -----
    <b><span style="color: #0000a0">cert-to-efi-sig-list -g $(< GUID.txt) KEK.crt KEK.esl</span></b>
    <b><span style="color: #0000a0">sig-list-to-certs ../svgkeys/svgKEK.esl svgKEK</span></b>
    X509 Header sls=1560, header=0, sig=1516
    file svgKEK-0.der: Guid 77fa9abd-0359-4d32-bd60-28f4e78f784b
    Written 1516 bytes
    X509 Header sls=959, header=0, sig=915
    file svgKEK-1.der: Guid 92fcafcd-c861-4b8b-aff2-a3d5a3e093f8
    Written 915 bytes
    <b><span style="color: #0000a0">openssl x509 -inform der -in svgKEK-0.der -noout -subject</span></b>
    subject=C = US, ST = Washington, L = Redmond, O = Microsoft Corporation, CN = Microsoft Corporation KEK CA 2011
    <b><span style="color: #0000a0">openssl x509 -inform der -in svgKEK-1.der -noout -subject</span></b>
    subject=C = Taiwan, ST = TW, L = Taipei, O = Acer, CN = Acer Key Exchange Key
    <b><span style="color: #0000a0">cat ../svgkeys/svgKEK.esl KEK.esl > newKEK.esl</span></b>
    <b><span style="color: #0000a0">sign-efi-sig-list -g $(< GUID.txt) -c PK.crt -k PK.key KEK newKEK.esl newKEK.auth</span></b>
    Timestamp is 2020-6-1 15:48:21
    Authentication Payload size 3894
    Enter PEM pass phrase:
    Signature of size 1928
    Signature at: 40
    <b><span style="color: #0000a0">efi-readvar -v KEK</span></b>
    Variable KEK has no entries
    <b><span style="color: #0000a0">sudo efi-updatevar -f newKEK.auth KEK</span></b>
    <b><span style="color: #0000a0">efi-readvar -v KEK</span></b>
    Variable KEK, length 3852
    KEK: List 0, type X509
        Signature 0, size 1532, owner 77fa9abd-0359-4d32-bd60-28f4e78f784b
            Subject:
                C=US, ST=Washington, L=Redmond, O=Microsoft Corporation, CN=Microsoft Corporation KEK CA 2011
            Issuer:
                C=US, ST=Washington, L=Redmond, O=Microsoft Corporation, CN=Microsoft Corporation Third Party Marketplace Root
    KEK: List 1, type X509
        Signature 0, size 931, owner 92fcafcd-c861-4b8b-aff2-a3d5a3e093f8
            Subject:
                C=Taiwan, ST=TW, L=Taipei, O=Acer, CN=Acer Key Exchange Key
            Issuer:
                C=Taiwan, ST=TW, L=Taipei, O=Acer, CN=Acer Root CA
    KEK: List 2, type X509
        Signature 0, size 1305, owner 68b8e83c-3fc1-4070-99be-d862b3531421
            Subject:
                CN=SMT KEK
            Issuer:
                CN=SMT KEK
    <b><span style="color: #0000a0">./fpcer.sh KEK.crt</span></b>
    A9:BA:33:0F:49:A0:02:1D:4A:A9:B6:25:37:98:2C:F1:62:F9:64:0C [SMT KEK]
    <b><span style="color: #0000a0">./fpvar.sh KEK</span></b>
    31:59:0B:FD:89:C9:D7:4E:D0:87:DF:AC:66:33:4B:39:31:25:4B:30 [Microsoft Corporation KEK CA 2011]
    25:18:D1:FF:33:47:AE:C8:02:40:5B:10:CF:71:1A:EC:6E:99:03:93 [Acer Key Exchange Key]
    A9:BA:33:0F:49:A0:02:1D:4A:A9:B6:25:37:98:2C:F1:62:F9:64:0C [SMT KEK]
</code></pre>

***

4. Add your certificate to db
-----------------------------

We'll also restore dbx content as it was before wipe.

Note that we'll remove certain db entries - I've no concern with leaving
Microsoft or Acer certificates, but I don't know who PEGA-SW2 belongs to.

### 4.1. Main method (entering Setup Mode)

<pre><code>    <b><span style="color: #b00000"># db</span></b>

    <b><span style="color: #0000a0">openssl req -utf8 -newkey rsa:4096 -keyout db.key -new -x509 -sha256 -days 3650 -subj "/CN=SMT db/" -out db.crt</span></b>
    Generating a RSA private key
    .............................................................................................................++++
    .................................................................................................................................................++++
    writing new private key to 'db.key'
    Enter PEM pass phrase:
    Verifying - Enter PEM pass phrase:
    -----
    <b><span style="color: #0000a0">cert-to-efi-sig-list -g $(< GUID.txt) db.crt db.esl</span></b>
    <b><span style="color: #0000a0">cat ../svgkeys/svgdb.esl db.esl > newdb.esl</span></b>
    <b><span style="color: #0000a0">sudo chattr -i /sys/firmware/efi/efivars/PK-8be4df61-93ca-11d2-aa0d-00e098032b8c</span></b>
    <b><span style="color: #0000a0">sudo efi-updatevar -d 0 -k PK.key PK</span></b>
    Enter PEM pass phrase:
    <b><span style="color: #0000a0">efi-readvar -v PK</span></b>
    Variable PK has no entries
    <b><span style="color: #0000a0">efi-readvar -v db</span></b>
    Variable db has no entries
    <b><span style="color: #0000a0">sudo efi-updatevar -a -e -f newdb.esl db</span></b>
    <b><span style="color: #0000a0">efi-readvar -v db</span></b>
    Variable db, length 6326
    db: List 0, type X509
        Signature 0, size 1515, owner 77fa9abd-0359-4d32-bd60-28f4e78f784b
            Subject:
                C=US, ST=Washington, L=Redmond, O=Microsoft Corporation, CN=Microsoft Windows Production PCA 2011
            Issuer:
                C=US, ST=Washington, L=Redmond, O=Microsoft Corporation, CN=Microsoft Root Certificate Authority 2010
    db: List 1, type X509
        Signature 0, size 1572, owner 77fa9abd-0359-4d32-bd60-28f4e78f784b
            Subject:
                C=US, ST=Washington, L=Redmond, O=Microsoft Corporation, CN=Microsoft Corporation UEFI CA 2011
            Issuer:
                C=US, ST=Washington, L=Redmond, O=Microsoft Corporation, CN=Microsoft Corporation Third Party Marketplace Root
    db: List 2, type X509
        Signature 0, size 923, owner 92fcafcd-c861-4b8b-aff2-a3d5a3e093f8
            Subject:
                C=Taiwan, ST=TW, L=Taipei, O=Acer, CN=Acer Database
            Issuer:
                C=Taiwan, ST=TW, L=Taipei, O=Acer, CN=Acer Root CA
    db: List 3, type X509
        Signature 0, size 797, owner 92fcafcd-c861-4b8b-aff2-a3d5a3e093f8
            Subject:
                CN=PEGA-SW2
            Issuer:
                CN=PEGA-SW2
    db: List 4, type SHA256
        Signature 0, size 48, owner 00000000-0000-0000-0000-000000000000
            Hash:bab37508f6f54874299edbe378ebbd76ba48abf74da68e816da5bf00434b442f
    db: List 5, type X509
        Signature 0, size 1303, owner 68b8e83c-3fc1-4070-99be-d862b3531421
            Subject:
                CN=SMT db
            Issuer:
                CN=SMT db
    <b><span style="color: #0000a0">sudo chattr -i /sys/firmware/efi/efivars/db-d719b2cb-3d3a-4596-a3bc-dad00e67656f</span></b>
    <b><span style="color: #0000a0">sudo efi-updatevar -d 4 db</span></b>
    <b><span style="color: #0000a0">sudo efi-updatevar -d 3 db</span></b>
    <b><span style="color: #0000a0">efi-readvar -v db</span></b>
    Variable db, length 5425
    db: List 0, type X509
        Signature 0, size 1515, owner 77fa9abd-0359-4d32-bd60-28f4e78f784b
            Subject:
                C=US, ST=Washington, L=Redmond, O=Microsoft Corporation, CN=Microsoft Windows Production PCA 2011
            Issuer:
                C=US, ST=Washington, L=Redmond, O=Microsoft Corporation, CN=Microsoft Root Certificate Authority 2010
    db: List 1, type X509
        Signature 0, size 1572, owner 77fa9abd-0359-4d32-bd60-28f4e78f784b
            Subject:
                C=US, ST=Washington, L=Redmond, O=Microsoft Corporation, CN=Microsoft Corporation UEFI CA 2011
            Issuer:
                C=US, ST=Washington, L=Redmond, O=Microsoft Corporation, CN=Microsoft Corporation Third Party Marketplace Root
    db: List 2, type X509
        Signature 0, size 923, owner 92fcafcd-c861-4b8b-aff2-a3d5a3e093f8
            Subject:
                C=Taiwan, ST=TW, L=Taipei, O=Acer, CN=Acer Database
            Issuer:
                C=Taiwan, ST=TW, L=Taipei, O=Acer, CN=Acer Root CA
    db: List 3, type X509
        Signature 0, size 1303, owner 68b8e83c-3fc1-4070-99be-d862b3531421
            Subject:
                CN=SMT db
            Issuer:
                CN=SMT db
    <b><span style="color: #0000a0">./fpcer.sh db.crt</span></b>
    D7:E0:E3:F8:E1:CE:D0:36:DF:2E:3B:7A:B6:E5:D0:CE:78:E7:22:72 [SMT db]
    <b><span style="color: #0000a0">./fpvar.sh db</span></b>
    58:0A:6F:4C:C4:E4:B6:69:B9:EB:DC:1B:2B:3E:08:7B:80:D0:67:8D [Microsoft Windows Production PCA 2011]
    46:DE:F6:3B:5C:E6:1C:F8:BA:0D:E2:E6:63:9C:10:19:D0:ED:14:F3 [Microsoft Corporation UEFI CA 2011]
    61:AA:ED:0E:D5:86:B5:FA:72:7B:C9:31:8C:15:7F:6A:A9:E8:BE:00 [Acer Database]
    D7:E0:E3:F8:E1:CE:D0:36:DF:2E:3B:7A:B6:E5:D0:CE:78:E7:22:72 [SMT db]

    <b><span style="color: #b00000"># dbx</span></b>

    <b><span style="color: #0000a0">efi-readvar -v dbx</span></b>
    Variable dbx has no entries
    <b><span style="color: #0000a0">sudo efi-updatevar -a -e -f ../svgkeys/svgdbx.esl dbx</span></b>
    <b><span style="color: #0000a0">efi-readvar -v dbx</span></b>
    Variable dbx, length 4685
    dbx: List 0, type SHA256
        Signature 0, size 48, owner 77fa9abd-0359-4d32-bd60-28f4e78f784b
            Hash:80b4d96931bf0d02fd91a61e19d14f1da452e66db2408ca8604d411f92659f0a
        [...]
        Signature 76, size 48, owner 77fa9abd-0359-4d32-bd60-28f4e78f784b
            Hash:45c7c8ae750acfbb48fc37527d6412dd644daed8913ccd8a24c94d856967df8e
    dbx: List 1, type X509
        Signature 0, size 933, owner 92fcafcd-c861-4b8b-aff2-a3d5a3e093f8
            Subject:
                C=Taiwan, ST=TW, L=Taipei, O=Acer, CN=Acer Database Forbidden
            Issuer:
                C=Taiwan, ST=TW, L=Taipei, O=Acer, CN=Acer Root CA
    <b><span style="color: #0000a0">sudo efi-updatevar -f PK.auth PK</span></b>
    <b><span style="color: #0000a0">efi-readvar -v PK</span></b>
    Variable PK, length 1331
    PK: List 0, type X509
        Signature 0, size 1303, owner 68b8e83c-3fc1-4070-99be-d862b3531421
            Subject:
                CN=SMT PK
            Issuer:
                CN=SMT PK
</code></pre>

### 4.2. Alternate method (User Mode)

<pre><code>    <b><span style="color: #b00000"># db</span></b>

    <b><span style="color: #0000a0">openssl req -utf8 -newkey rsa:4096 -keyout db.key -new -x509 -sha256 -days 3650 -subj "/CN=SMT db/" -out db.crt</span></b>
    Generating a RSA private key
    .............................................................................................................++++
    .................................................................................................................................................++++
    writing new private key to 'db.key'
    Enter PEM pass phrase:
    Verifying - Enter PEM pass phrase:
    -----
    <b><span style="color: #0000a0">cert-to-efi-sig-list -g $(< GUID.txt) db.crt db.esl</span></b>
    <b><span style="color: #0000a0">cat ../svgkeys/svgdb.esl db.esl > newdb.esl</span></b>
    <b><span style="color: #0000a0">efi-readvar -v db</span></b>
    Variable db has no entries
    <b><span style="color: #0000a0">sign-efi-sig-list -a -g $(< GUID.txt) -c KEK.crt -k KEK.key db newdb.esl newdb.auth</span></b>
    Timestamp is 0-0-0 00:00:00
    Authentication Payload size 6366
    Enter PEM pass phrase:
    Signature of size 1931
    Signature at: 40
    <b><span style="color: #0000a0">sudo efi-updatevar -a -g $(< GUID.txt) -f newdb.auth db</span></b>
    <b><span style="color: #0000a0">efi-readvar -v db</span></b>
    Variable db, length 6326
    db: List 0, type X509
        Signature 0, size 1515, owner 77fa9abd-0359-4d32-bd60-28f4e78f784b
            Subject:
                C=US, ST=Washington, L=Redmond, O=Microsoft Corporation, CN=Microsoft Windows Production PCA 2011
            Issuer:
                C=US, ST=Washington, L=Redmond, O=Microsoft Corporation, CN=Microsoft Root Certificate Authority 2010
    db: List 1, type X509
        Signature 0, size 1572, owner 77fa9abd-0359-4d32-bd60-28f4e78f784b
            Subject:
                C=US, ST=Washington, L=Redmond, O=Microsoft Corporation, CN=Microsoft Corporation UEFI CA 2011
            Issuer:
                C=US, ST=Washington, L=Redmond, O=Microsoft Corporation, CN=Microsoft Corporation Third Party Marketplace Root
    db: List 2, type X509
        Signature 0, size 923, owner 92fcafcd-c861-4b8b-aff2-a3d5a3e093f8
            Subject:
                C=Taiwan, ST=TW, L=Taipei, O=Acer, CN=Acer Database
            Issuer:
                C=Taiwan, ST=TW, L=Taipei, O=Acer, CN=Acer Root CA
    db: List 3, type X509
        Signature 0, size 797, owner 92fcafcd-c861-4b8b-aff2-a3d5a3e093f8
            Subject:
                CN=PEGA-SW2
            Issuer:
                CN=PEGA-SW2
    db: List 4, type SHA256
        Signature 0, size 48, owner 00000000-0000-0000-0000-000000000000
            Hash:bab37508f6f54874299edbe378ebbd76ba48abf74da68e816da5bf00434b442f
    db: List 5, type X509
        Signature 0, size 1303, owner 68b8e83c-3fc1-4070-99be-d862b3531421
            Subject:
                CN=SMT db
            Issuer:
                CN=SMT db
    <b><span style="color: #0000a0">sudo chattr -i /sys/firmware/efi/efivars/db-d719b2cb-3d3a-4596-a3bc-dad00e67656f</span></b>
    <b><span style="color: #0000a0">sudo efi-updatevar -d 4 -k KEK.key db</span></b>
    Enter PEM pass phrase:
    <b><span style="color: #b00000">139749163805568:error:0B080074:x509 certificate routines:X509_check_private_key:key values mismatch:crypto/x509/x509_cmp.c:297:
    139749163805568:error:0B080074:x509 certificate routines:X509_check_private_key:key values mismatch:crypto/x509/x509_cmp.c:297:</span></b>
    <b><span style="color: #0000a0">sudo efi-updatevar -d 3 -k KEK.key db</span></b>
    Enter PEM pass phrase:
    <b><span style="color: #b00000">139855970536320:error:0B080074:x509 certificate routines:X509_check_private_key:key values mismatch:crypto/x509/x509_cmp.c:297:
    139855970536320:error:0B080074:x509 certificate routines:X509_check_private_key:key values mismatch:crypto/x509/x509_cmp.c:297:</span></b>
    <b><span style="color: #0000a0">efi-readvar -v db</span></b>
    Variable db, length 5425
    db: List 0, type X509
        Signature 0, size 1515, owner 77fa9abd-0359-4d32-bd60-28f4e78f784b
            Subject:
                C=US, ST=Washington, L=Redmond, O=Microsoft Corporation, CN=Microsoft Windows Production PCA 2011
            Issuer:
                C=US, ST=Washington, L=Redmond, O=Microsoft Corporation, CN=Microsoft Root Certificate Authority 2010
    db: List 1, type X509
        Signature 0, size 1572, owner 77fa9abd-0359-4d32-bd60-28f4e78f784b
            Subject:
                C=US, ST=Washington, L=Redmond, O=Microsoft Corporation, CN=Microsoft Corporation UEFI CA 2011
            Issuer:
                C=US, ST=Washington, L=Redmond, O=Microsoft Corporation, CN=Microsoft Corporation Third Party Marketplace Root
    db: List 2, type X509
        Signature 0, size 923, owner 92fcafcd-c861-4b8b-aff2-a3d5a3e093f8
            Subject:
                C=Taiwan, ST=TW, L=Taipei, O=Acer, CN=Acer Database
            Issuer:
                C=Taiwan, ST=TW, L=Taipei, O=Acer, CN=Acer Root CA
    db: List 3, type X509
        Signature 0, size 1303, owner 68b8e83c-3fc1-4070-99be-d862b3531421
            Subject:
                CN=SMT db
            Issuer:
                CN=SMT db

    <b><span style="color: #b00000"># dbx</span></b>

    <b><span style="color: #0000a0">efi-readvar -v dbx</span></b>
    Variable dbx has no entries
    <b><span style="color: #0000a0">sign-efi-sig-list -a -g $(< GUID.txt) -c KEK.crt -k KEK.key dbx ../svgkeys/svgdbx.esl svgdbx.auth</span></b>
    Timestamp is 0-0-0 00:00:00
    Authentication Payload size 4727
    Enter PEM pass phrase:
    Signature of size 1931
    Signature at: 40
    <b><span style="color: #0000a0">sudo efi-updatevar -a -g $(< GUID.txt) -f svgdbx.auth dbx</span></b>
    <b><span style="color: #0000a0">efi-readvar -v dbx</span></b>
    Variable dbx, length 4685
    dbx: List 0, type SHA256
        Signature 0, size 48, owner 77fa9abd-0359-4d32-bd60-28f4e78f784b
            Hash:80b4d96931bf0d02fd91a61e19d14f1da452e66db2408ca8604d411f92659f0a
        [...]
        Signature 76, size 48, owner 77fa9abd-0359-4d32-bd60-28f4e78f784b
            Hash:45c7c8ae750acfbb48fc37527d6412dd644daed8913ccd8a24c94d856967df8e
    dbx: List 1, type X509
        Signature 0, size 933, owner 92fcafcd-c861-4b8b-aff2-a3d5a3e093f8
            Subject:
                C=Taiwan, ST=TW, L=Taipei, O=Acer, CN=Acer Database Forbidden
            Issuer:
                C=Taiwan, ST=TW, L=Taipei, O=Acer, CN=Acer Root CA
</code></pre>

As you can see, sometimes efi-updatevar produces an error, although it produced
expected result.

***

5. Entering and leaving Setup Mode
----------------------------------

### 5.1. Enter Setup Mode

*Setup Mode* allows to update variables without signature, that is, using .esl
files instead of .auth files.

<pre><code>    <b><span style="color: #0000a0">efi-readvar -v PK</span></b>
    Variable PK, length 1331
    PK: List 0, type X509
        Signature 0, size 1303, owner 68b8e83c-3fc1-4070-99be-d862b3531421
            Subject:
                CN=SMT PK
            Issuer:
                CN=SMT PK
    <b><span style="color: #0000a0">sudo chattr -i /sys/firmware/efi/efivars/PK-8be4df61-93ca-11d2-aa0d-00e098032b8c</span></b>
    <b><span style="color: #0000a0">sudo efi-updatevar -d 0 -k PK.key PK</span></b>
    Enter PEM pass phrase:
    <b><span style="color: #0000a0">efi-readvar -v PK</span></b>
    Variable PK has no entries
</code></pre>

### 5.2. Leave Setup Mode (= enter User Mode)

<pre><code>    <b><span style="color: #0000a0">efi-readvar -v PK</span></b>
    Variable PK has no entries
    <b><span style="color: #0000a0">sudo efi-updatevar -f PK.auth PK</span></b>
    <b><span style="color: #0000a0">efi-readvar -v PK</span></b>
    Variable PK, length 1331
    PK: List 0, type X509
        Signature 0, size 1303, owner 68b8e83c-3fc1-4070-99be-d862b3531421
            Subject:
                CN=SMT PK
            Issuer:
                CN=SMT PK
</code></pre>

***

6. Sign Linux binary
--------------------

We now own a certificate listed in db, that allows us to sign a binary.

Under Arch Linux, execute the below:
<pre><code>    <b><span style="color: #0000a0">cd /boot</span></b>
    <b><span style="color: #0000a0">sudo sbsign --cert ~/uefi/db.crt --key ~/uefi/db.key vmlinuz-linux</span></b>
    Enter PEM pass phrase:
    Signing Unsigned original image
    <b><span style="color: #0000a0">ls -l vmlinuz-linux vmlinuz-linux.signed</span></b>
    -rwxr-xr-x 1 root root 6733600  1 juin  10:08 vmlinuz-linux
    -rwxr-xr-x 1 root root 6735896  3 juin  07:01 vmlinuz-linux.signed
</code></pre>

You now have to update Boot Loader accordingly, and you're done! You can enable
Secure Boot.

Note that Arch Linux updates the kernel frequently and signing it manually is
not ideal.

Note

You also have to sign boot loader *efi* file before you can start with Secure
Boot enabled.  On Arch Linux with bootctl, the file is

*/boot/EFI/systemd/systemd-bootx64.efi*

***

7. Issues encountered while writing this document
-------------------------------------------------

   1. When a file contains a signature, it gets the *.auth* extension.
      *.signed* would be clearer. I find "authenticated" word more suitable for
      transactions, not files at rest.

      The thing is, KeyTool does not recognize a file with *.signed* extension.
      It is therefore best to keep using standard extension, *.auth*.

   2. Modifying db sometimes leads to a corrupt db, of length *-4*. When in this
      situation, the workaround is to reboot. This issue has also been
      encountered with other variables, although less frequently.

   3. In db, I didn't install all certificates found there by default.

      In particular, I didn't want the entry *PEGA-SW2*, that I don't know the
      purpose of.

      A first idea was to extract *svgdb.esl* as a list of certificates, then
      re-build a new *.esl* file with certificates of my choice.

      Doing this way works but the entries GUID is made of zeros. I don't know
      if that's critical, but I preferred the solution of adding initial *.esl*
      then deleting entries I don't want. This creates entries with their
      initial GUID.

      Another solution would be to make sure proper GUID is provided when
      executing *cert-to-efi-sig-list*.

   4. When creating *.esl* files from certificates using *cert-to-efi-sig-list*,
      the certificates must be in PEM format. If not, it looks like it worked
      fine although it creates a broken *.esl* file of 44 bytes.

   5. Updating db seems to always need the *-a* option. The author could never
      get to do the update without this option, even would db be empty at the
      time *efi-updatevar* is executed.

   6. Certain calls to *efi-updatevar* produce an error, although the call
      produced expected result. It has been seen when deleting entries from db,
      while in User Mode.

   7. Some actions implicitly enter User Mode, like : restoring variables to
      their default values in UEFI interface or starting Windows.

      In general, it is not always straightforward to work out whether or not
      the PC is in Setup Mode. One might say "it is in Setup Mode if and only if
      PK is empty", but this criteria becomes unclear if PK reading produces an
      error about negative variable length. At times, I found the most reliable
      way was, to start PC on KeyTool.efi and see what KeyTool says. This has
      always been 100% reliable.

***

8. <a name="abstract-of-commands"></a>Abstract of commands
-----------------------

<pre><code><b><span style="color: #b00000"># Assumption: PK, KEK, db and dbx are set to default values</span></b>

<span style="color: #b00000"># Backup of existing keys</span>
<span style="color: #0000a0">mkdir svgkeys</span>
<span style="color: #0000a0">cd svgkeys/</span>
<span style="color: #0000a0">efi-readvar -v PK -o svgPK.esl</span>
<span style="color: #0000a0">efi-readvar -v KEK -o svgKEK.esl</span>
<span style="color: #0000a0">efi-readvar -v db -o svgdb.esl</span>
<span style="color: #0000a0">efi-readvar -v dbx -o svgdbx.esl</span>

<b><span style="color: #b00000"># New assumption: PK, KEK, db and dbx are now empty</span></b>
<b><span style="color: #b00000"># This implies, you've just entered Setup Mode</span></b>

<span style="color: #b00000"># Creation of PK and writing to PK - MUST BE IN SETUP MODE</span>
<span style="color: #0000a0">cd ..</span>
<span style="color: #0000a0">mkdir uefi</span>
<span style="color: #0000a0">cd uefi</span>
<span style="color: #0000a0">uuidgen > GUID.txt</span>
<span style="color: #0000a0">openssl req -utf8 -newkey rsa:4096 -keyout PK.key -new -x509 -sha256 -days 3650 -subj "/CN=SMT PK/" -out PK.crt</span>
<span style="color: #0000a0">cert-to-efi-sig-list -g $(< GUID.txt) PK.crt PK.esl</span>
<span style="color: #0000a0">sign-efi-sig-list -g $(< GUID.txt) -c PK.crt -k PK.key PK PK.esl PK.auth</span>
<span style="color: #0000a0">sudo efi-updatevar -f PK.auth PK</span>

<span style="color: #b00000"># Creation of KEK and writing to KEK</span>
<span style="color: #0000a0">openssl req -utf8 -newkey rsa:4096 -keyout KEK.key -new -x509 -sha256 -days 3650 -subj "/CN=SMT KEK/" -out KEK.crt</span>
<span style="color: #0000a0">cert-to-efi-sig-list -g $(< GUID.txt) KEK.crt KEK.esl</span>
<span style="color: #0000a0">cat ../svgkeys/svgKEK.esl KEK.esl > newKEK.esl</span>
<span style="color: #0000a0">sign-efi-sig-list -g $(< GUID.txt) -c PK.crt -k PK.key KEK newKEK.esl newKEK.auth</span>
<span style="color: #0000a0">sudo efi-updatevar -f newKEK.auth KEK</span>

<span style="color: #b00000"># Creation of db and writing to db</span>
<span style="color: #0000a0">openssl req -utf8 -newkey rsa:4096 -keyout db.key -new -x509 -sha256 -days 3650 -subj "/CN=SMT db/" -out db.crt</span>
<span style="color: #0000a0">cert-to-efi-sig-list -g $(< GUID.txt) db.crt db.esl</span>
<span style="color: #0000a0">cat ../svgkeys/svgdb.esl db.esl > newdb.esl</span>
<span style="color: #0000a0">sign-efi-sig-list -a -g $(< GUID.txt) -c KEK.crt -k KEK.key db newdb.esl newdb.auth</span>
<span style="color: #0000a0">sudo efi-updatevar -a -g $(< GUID.txt) -f newdb.auth db</span>
<span style="color: #0000a0">sudo chattr -i /sys/firmware/efi/efivars/db-d719b2cb-3d3a-4596-a3bc-dad00e67656f</span>
<span style="color: #b00000"># Delete entries if needed, below, example for entry number 4</span>
<span style="color: #0000a0">sudo efi-updatevar -d 4 -k KEK.key db</span>

<span style="color: #b00000"># Restoration of dbx</span>
<span style="color: #0000a0">sign-efi-sig-list -a -g $(< GUID.txt) -c KEK.crt -k KEK.key dbx ../svgkeys/svgdbx.esl svgdbx.auth</span>
<span style="color: #0000a0">sudo efi-updatevar -a -g $(< GUID.txt) -f svgdbx.auth dbx</span>

<span style="color: #b00000"># Enter Setup Mode</span>
<span style="color: #0000a0">sudo chattr -i /sys/firmware/efi/efivars/PK-8be4df61-93ca-11d2-aa0d-00e098032b8c</span>
<span style="color: #0000a0">sudo efi-updatevar -d 0 -k PK.key PK</span>

<span style="color: #b00000"># Leave Setup Mode (= enter User Mode)</span>
<span style="color: #0000a0">sudo efi-updatevar -f PK.auth PK</span>

<span style="color: #b00000"># Sign Linux binary</span>
<span style="color: #0000a0">sudo sbsign --cert ~/uefi/db.crt --key ~/uefi/db.key vmlinuz-linux</span>

</code></pre>

***

customsb.md (c) by Sébastien Millet

customsb.md is licensed under a
Creative Commons Attribution 4.0 International License.

You should have received a copy of the license along with this
work. If not, see <http://creativecommons.org/licenses/by/4.0/>.

[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)

<!--- vim: tw=80:ts=4:sw=4:et
-->

