#include <iostream>
#include <thread>
#include <vector>
#include <time.h>
#include "bitmap_image.hpp"
#include <Windows.h>

using namespace std;

// Definiujemy typ (?)
typedef void(_fastcall *MainProcedure) (unsigned char**, int, int, int, double, double, double, double);
typedef void(_fastcall *MainProcedure2)(unsigned char**, int, int, int, float, float, float, float);

// Uchwyt do biblioteki
HINSTANCE dllHandle1 = NULL, dllHandle2 = NULL;

void AllocateMemory(unsigned char** &imagePixels, unsigned int imageWidth, unsigned int imageHeight)
{
	imagePixels = new unsigned char*[imageHeight];
	for (unsigned int i = 0; i < imageHeight; i++)
	{
		imagePixels[i] = new unsigned char[imageWidth];
	}
}


void setArrayPartsRanges(vector<pair<int, int> > &partsRanges, int numberOfLines, int numberOfParts)
{
	int size = numberOfLines / numberOfParts;
	int remainder = numberOfLines % numberOfParts;
	int buffer = 0;

	for (int i = 0; i < remainder; i++)
	{
		partsRanges.emplace_back(pair<int, int>(buffer, size + 1));
		buffer += size + 1;
	}
	for (int i = remainder; i < numberOfParts; i++)
	{
		partsRanges.emplace_back(pair<int, int>(buffer, size));
		buffer += size;
	}

}


void GenerateImageFromArray(unsigned char** &imagePixels, unsigned int imageWidth, unsigned int imageHeight)
{

	bitmap_image image(imageWidth, imageHeight);
	image.clear();


	for (unsigned int i = 0; i < imageHeight; i++)
	{
		for (unsigned int j = 0; j < imageWidth; j++)
		{
			unsigned char colorSaturation = imagePixels[i][j];

			image.set_pixel(j, i, colorSaturation, colorSaturation, colorSaturation);
		}
	}

	const string filename{ "mandelbrot_set.bmp" };

	image.save_image(filename);

	cout << "Saved image to \"" << filename << "\"." << endl;

	//print(imagePixels, 30, 100);
}


void ClearMemory(unsigned char** &imagePixels, unsigned int imageHeight)
{
	// Clearing memory
	for (unsigned int i = 0; i < imageHeight; i++)
	{
		delete imagePixels[i];
	}
	delete imagePixels;
}


// Prints an array
void print(unsigned char ** Array, int columns, int lines)
{
	for (int i = 0; i < lines; i++)
	{
		for (int j = 0; j < columns; j++)
		{
			cout << (int)Array[i][j] << "  ";
		}
		cout << endl;// << endl;
	}
}



int main2(int argc, char **argv)
{
	// Loading libraries

	dllHandle1 = LoadLibrary("DLL_Asm.dll");
	dllHandle2 = LoadLibrary("DLL_C.dll");

	MainProcedure asm_procedure = (MainProcedure)GetProcAddress(dllHandle1, "MandelbrotTest_Asm");

	MainProcedure c_procedure = (MainProcedure)GetProcAddress(dllHandle2, "MandelbrotTest_C");

	unsigned int imageWidth{ 900 };
	unsigned int imageHeight{ 600 };

	double X1 = -2.0, X2 = 1.0;
	double Y1 = -1.0, Y2 = 1.0;

	int hard_con = thread::hardware_concurrency();
	cout << "Hardware concurrency: " << hard_con << endl;

	int numberOfThreads{ hard_con };


	if (argc >= 1)
	{
		numberOfThreads = stoi(argv[1]);
		cout << "Used threads: " << argv[1] << endl;
		if (argc >= 3)
		{
			imageWidth = stoi(argv[2]);
			imageHeight = stoi(argv[3]);
			cout << "Image width: " << argv[2] << endl;
			cout << "Image height: " << argv[3] << endl;
		}
	}

	//cout << endl << "Enter->continue" << endl;
	//cin.get();

	//unsigned char ** imagePixels;

	vector<thread> threadVector;
	vector<pair<int, int> > partsRanges;


	// Allocating memory

	//AllocateMemory(imagePixels, imageWidth, imageHeight);

	// Setting proper ranges for array parts

	//setArrayPartsRanges(partsRanges, imageHeight, numberOfThreads);


	clock_t start, stop;
	start = clock();


	// Processing procedure without dividing into threads

	int liczbaWierszy = 30;
	int liczbaKolumn = 25;


	unsigned char ** tablica1 = new unsigned char *[liczbaWierszy];
	for (int i = 0; i < liczbaWierszy; i++)
	{
		tablica1[i] = new unsigned char[liczbaKolumn];
	}

	/*printf("tablica: %p\n", tablica1);
	printf("tablica[0]: %p\n", tablica1[0]);

	printf("\n");*/

	std::cout << "tablica: " << tablica1 << std::endl;
	std::cout << "tablica[0]: " << (void *)(tablica1[0]) << std::endl;
	std::cout << "&tablica[0][0]: " << static_cast<void *>(&tablica1[0][0]) << std::endl;
	std::cout << "&tablica[0][1]: " << static_cast<void *>(&tablica1[0][1]) << std::endl;
	std::cout << "tablica[1]: " << static_cast<void *>(tablica1[1]) << std::endl;
	std::cout << "&tablica[1][0]: " << static_cast<void *>(&tablica1[1][0]) << std::endl;
	std::cout << "&tablica[1][1]: " << static_cast<void *>(&tablica1[1][1]) << std::endl;
	std::cout << "&tablica[1][2]: " << static_cast<void *>(&tablica1[1][2]) << std::endl;


	asm_procedure(tablica1, 0, liczbaWierszy, liczbaKolumn, 0.33, 0.33, 0.335, 2.255);


	std::cout << "-------" << std::endl;

	print(tablica1, liczbaKolumn, liczbaWierszy);


	ClearMemory(tablica1, liczbaWierszy);



	/*
	for (int i = 0; i < numberOfThreads; i++)
	{
		asm_procedure(imagePixels, partsRanges[i].first, partsRanges[i].second, imageWidth,
			X1, X2, Y1, Y2);
	}*/

	/*

	// Splitting generation process into threads

	for (int i = 0; i < numberOfThreads; i++)
	{
		threadVector.emplace_back(thread(c_procedure, imagePixels, partsRanges[i].first, partsRanges[i].second,
			imageWidth, X1, X2, Y1, Y2));
	}


	for (int i = 0; i < numberOfThreads; i++)
	{
		threadVector[i].join();
	}

	*/



	stop = clock();

	double timeElapsed = (double)((stop - start) / (double)CLOCKS_PER_SEC);

	cout << "Time elapsed: " << timeElapsed << endl;


	//GenerateImageFromArray(imagePixels, imageWidth, imageHeight);

	//ClearMemory(imagePixels, imageHeight);


	cout << endl << "Program ended <Press Enter>";
	cin.get();
	return 0;
}