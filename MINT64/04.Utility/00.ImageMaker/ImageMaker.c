#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>

#define BYTESOFSECTOR	512

int AdjustInSectorSize(int iFd, int iSourceSize);
void WriteKernelInformation(int iTargetFd, int iTotalKernelSectorCount,
		int iKernel32SectorCount);
int CopyFile(int iSourceFd, int iTargetFd);

int main(int argc, char *argv[])
{
	int iSourceFd, iTargetFd;
	int iBootLoaderSize, iKernel32SectorCount, iKernel64SectorCount, iSourceSize;

	if (argc < 4)
	{
		fprintf(stderr, "[Error] ImageMaker.out BootLoader.bin Kernel32.bin Kernel64.bin\n");
		exit(-1);
	}

	// Make Disk.img file
	if ( (iTargetFd = open("Disk.img", O_RDWR | O_CREAT | O_TRUNC
					, S_IREAD | S_IWRITE) ) == -1)
	{
		fprintf(stderr, "[Error] Disk.img open fail.\n");
		exit(-1);
	}

	// open boot loader file and copy to Disk image file
	printf("[Info] Copy boot loader to image file\n");
	if ( (iSourceFd = open(argv[1], O_RDONLY)) == -1 )
	{
		fprintf(stderr, "[Error] %s open fail\n", argv[1]);
		exit(-1);
	}

	iSourceSize = CopyFile(iSourceFd, iTargetFd);
	close(iSourceFd);

	iBootLoaderSize = AdjustInSectorSize(iTargetFd, iSourceSize);
	printf("[Info] %s size = [%d] and sector count = [%d] \n",
			argv[1], iSourceSize, iBootLoaderSize);

	// open 32bit kernel file and copy to Disk image file
	printf("[Info] Copy protected mode kernel to image file\n");
	if ((iSourceFd = open(argv[2], O_RDONLY)) == -1)
	{
		fprintf(stderr, "[Error] %s open fail.\n", argv[2]);
		exit(-1);
	}

	iSourceSize = CopyFile(iSourceFd, iTargetFd);
	close(iSourceFd);

	// align sector size with 0x00
	iKernel32SectorCount = AdjustInSectorSize(iTargetFd, iSourceSize);
	printf("[Info] %s size = [%d] and sector count = [%d]\n",
			argv[2], iSourceSize, iKernel32SectorCount);

	// open 64bit kernel file and copy to Disk image file
	printf("[Info] Copy IA-32e mode kernel to image file\n");
	if ((iSourceFd = open(argv[3], O_RDONLY)) == -1)
	{
		fprintf(stderr, "[Error] %s open fail\n", argv[3]);
		exit(-1);
	}

	iSourceSize = CopyFile(iSourceFd, iTargetFd);
	close(iSourceFd);

	iKernel64SectorCount = AdjustInSectorSize(iTargetFd, iSourceSize);
	printf("[Info] %s size = [%d] and sector count = [%d]\n",
			argv[3], iSourceSize, iKernel64SectorCount);

	// renew kernel information to disk image
	printf("[Info] Start to write kernel information \n");
	WriteKernelInformation(iTargetFd, iKernel32SectorCount + iKernel64SectorCount,
			iKernel32SectorCount);
	printf("[Info] Image file create complete \n");

	close(iTargetFd);
	return 0;
}

int AdjustInSectorSize(int iFd, int iSourceSize)
{
	int i;
	int iAdjustSizeToSector;
	char cCh;
	int iSectorCount;

	iAdjustSizeToSector = iSourceSize % BYTESOFSECTOR;
	cCh = 0x00;

	if (iAdjustSizeToSector != 0)
	{
		iAdjustSizeToSector = 512 - iAdjustSizeToSector;
		printf("[Info] File size [%d] and fill [%d] byte\n", iSourceSize,
				iAdjustSizeToSector);
		for (i = 0; i < iAdjustSizeToSector; ++i)
		{
			write(iFd, &cCh, 1);
		}
	}
	else
	{
		printf("[Info] File size is aligned 512 byte \n");
	}

	iSectorCount = (iSourceSize + iAdjustSizeToSector) / BYTESOFSECTOR;
	return iSectorCount;
}

void WriteKernelInformation(int iTargetFd, int iTotalKernelSectorCount,
		int iKernel32SectorCount)
{
	unsigned short usData;
	long lPosition;

	// full number of sectors is offset 5
	lPosition = lseek(iTargetFd, 5, SEEK_SET);
	if (lPosition == -1)
	{
		fprintf(stderr, "lseek fail. Return value = %ld, errno = %d, %d \n",
				lPosition, errno, SEEK_SET);
		exit(-1);
	}

	usData = (unsigned short)iTotalKernelSectorCount;
	write(iTargetFd, &usData, 2);
	usData = (unsigned short)iKernel32SectorCount;
	write(iTargetFd, &usData, 2);

	printf("[Info] Total sector count except boot loader [%d]\n",
			iTotalKernelSectorCount);
	printf("[Info] Total sector count of protected mode kernel [%d]\n",
			iKernel32SectorCount);
}

int CopyFile(int iSourceFd, int iTargetFd)
{
	int iSourceFileSize;
	int iRead, iWrite;
	char vcBuffer[BYTESOFSECTOR];

	iSourceFileSize = 0;
	while (1)
	{
		iRead = read(iSourceFd, vcBuffer, sizeof(vcBuffer));
		iWrite = write(iTargetFd, vcBuffer, iRead);

		if (iRead != iWrite)
		{
			fprintf(stderr, "[Error] iRead != iWrite.. \n");
			exit(-1);
		}

		iSourceFileSize += iRead;

		if (iRead != sizeof(vcBuffer))
		{
			break;
		}
	}

	return iSourceFileSize;
}
