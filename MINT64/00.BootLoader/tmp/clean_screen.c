int main()
{
	int i = 0;
	char *video_mem = (char *)0xB8000;

	for (;;)
	{
		video_mem[i] = 0;			// black background
		video_mem[i + 1] = 0x0A;	// green text

		i += 2;

		if (i >= 80 * 25 * 2)
			break;
	}
	
	return 0;
}
