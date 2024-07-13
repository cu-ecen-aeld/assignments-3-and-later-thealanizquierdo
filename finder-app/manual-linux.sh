#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-linux-gnu-

if [ $# -lt 1 ]
then
    echo "Using default directory ${OUTDIR} for output"
else
    OUTDIR=$1
    echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    # Clone only if the repository does not exist.
    echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
    git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi

if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # Kernel build steps
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig
    make -j$(nproc) ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE all
    cp arch/$ARCH/boot/Image ${OUTDIR}
fi

echo "Adding the Image in outdir"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]; then
    echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm -rf ${OUTDIR}/rootfs
fi

# Create necessary base directories
mkdir -p ${OUTDIR}/rootfs/{bin,sbin,etc,proc,sys,usr/{bin,sbin},dev,home}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]; then
    git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # Configure busybox
    make distclean
    make defconfig
else
    cd busybox
fi

# Make and install busybox
make -j$(nproc) ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE CONFIG_PREFIX=${OUTDIR}/rootfs install

echo "Library dependencies"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library"

# Add library dependencies to rootfs
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
cp -a ${SYSROOT}/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib
cp -a ${SYSROOT}/lib64/ld-2.31.so ${OUTDIR}/rootfs/lib64
cp -a ${SYSROOT}/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64
cp -a ${SYSROOT}/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64
cp -a ${SYSROOT}/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64

# Make device nodes
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
sudo mknod -m 600 ${OUTDIR}/rootfs/dev/console c 5 1

# Clean and build the writer utility
cd ${FINDER_APP_DIR}
make clean
make CROSS_COMPILE=$CROSS_COMPILE

# Copy the finder related scripts and executables to the /home directory on the target rootfs
cp finder.sh ${OUTDIR}/rootfs/home/
cp conf/username.txt ${OUTDIR}/rootfs/home/
cp conf/assignment.txt ${OUTDIR}/rootfs/home/
cp finder-test.sh ${OUTDIR}/rootfs/home/
cp autorun-qemu.sh ${OUTDIR}/rootfs/home/
cp writer ${OUTDIR}/rootfs/home/

# Modify finder-test.sh to use the correct path for assignment.txt
sed -i 's|\.\./conf/assignment.txt|/home/assignment.txt|' ${OUTDIR}/rootfs/home/finder-test.sh

# Chown the root directory
sudo chown -R root:root ${OUTDIR}/rootfs

# Create initramfs.cpio.gz
cd ${OUTDIR}/rootfs
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ${OUTDIR}/initramfs.cpio.gz

echo "Build completed successfully!"

