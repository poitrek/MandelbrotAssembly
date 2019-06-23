#include <iostream>
#include <thread>
#include <vector>
#include <time.h>
#include "bitmap_image.hpp"
#include <Windows.h>
#include <string>

using namespace std;

// Definiujemy typ (?)
//typedef void (_fastcall *MainProcedure) (unsigned char**, int, int, int, double, double, double, double);
typedef void(_fastcall *MainProcedure2)(unsigned char**, int, int, int);

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


void GenerateImageFromArray(unsigned char** &imagePixels, unsigned int imageWidth, unsigned int imageHeight,
	string imageFilename)
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

	image.save_image(imageFilename);

	cout << "Saved image to \"" << imageFilename << "\"." << endl;

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
void printArray(unsigned char ** Array, int columns, int lines)
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

// For testing
void initArray(unsigned char ** Array, int columns, int lines)
{
	int randomNumber = 71;
	for (int i = 0; i < lines; i++)
	{
		for (int j = 0; j < columns; j++)
		{
			Array[i][j] = j;
		}
	}
}


void sendToTxt(unsigned int numberOfThreads, double timeElapsed, bool useAsm)
{
	const string name{ "results.txt" };
	ofstream file;
	file.open(name, std::ios_base::app);

	file << numberOfThreads << " " << timeElapsed << " ";
	if (useAsm)
	{
		file << "asm" << endl;
	}
	else
	{
		file << "c" << endl;
	}

	file.close();
}


// Ultimate program main function

int main(int argc, char **argv)
{
	// Loading libraries

	dllHandle1 = LoadLibrary("DLL_Asm.dll");
	dllHandle2 = LoadLibrary("DLL_C.dll");

	MainProcedure2 asm_procedure = (MainProcedure2)GetProcAddress(dllHandle1, "MandelbrotTest_Asm");
	MainProcedure2 c_procedure = (MainProcedure2)GetProcAddress(dllHandle2, "MandelbrotTest_C");

	unsigned int imageWidth{ 900 };
	unsigned int imageHeight{ 600 };

	//float X1 = -2.0, X2 = 1.0;
	//float Y1 = -1.0, Y2 = 1.0;

	int hard_con = thread::hardware_concurrency();
	//cout << "Hardware concurrency: " << hard_con << endl;

	int numberOfThreads{ hard_con };

	bool useAsm{ true };

	// Handle parameters
	// parameters:	imageWidth, imageHeight, numOfThreads, c_or_asm

	if (argc >= 2)
	{
		imageWidth = stoi(argv[1]);
		imageHeight = stoi(argv[2]);
		cout << "Image: " << imageWidth << " x " << imageHeight << endl;
		
		if (argc >= 3)
		{
			numberOfThreads = stoi(argv[3]);
			cout << "Used threads: " << argv[3] << endl;
			if (argc >= 4)
			{
				if (strcmp(argv[4], "asm") == 0)
				{
					useAsm = true;
					cout << "Used dll: asm" << endl;
				}
				else // "c"
				{
					useAsm = false;
					cout << "Used dll: C" << endl;
				}
			}
		}
	}

	//============================================================================//

	//cout << endl << "Enter->continue" << endl;
	//cin.get();

	
	unsigned char ** imagePixels;
	vector<thread> threadVector;
	//		<beginLine, numberOfLines>
	vector<pair<int, int> > partsRanges; 

	// Image width extended to the nearest multiple of 4
	unsigned int imageWidthCeil = imageWidth + 4 - imageWidth % 4;


	// allocating memory
	AllocateMemory(imagePixels, imageWidthCeil, imageHeight);


	// setting proper ranges for array parts
	setArrayPartsRanges(partsRanges, imageHeight, numberOfThreads);


	auto start = chrono::steady_clock::now();

	//cout << "Measuring time excecution of 2nd thread." << endl;
	//thread t1(asm_procedure, imagePixels, partsRanges[1].first, partsRanges[1].second, imageWidth);
	//asm_procedure(imagePixels, partsRanges[1].first, partsRanges[1].second, imageWidth);
	//Sleep(3000);
	//t1.join();

	// Process procedure without multi-threading

	//for (int i = 0; i < numberOfThreads; i++)
	//{
	//	asm_procedure(imagePixels, partsRanges[i].first, partsRanges[i].second, imageWidth);
	//}
	//

	// Split generation process into threads

	if (useAsm)
	{
		for (int i = 0; i < numberOfThreads; i++)
		{
			threadVector.emplace_back(thread(asm_procedure, imagePixels, partsRanges[i].first, partsRanges[i].second,
				imageWidthCeil));
		}
	}
	else
	{
		for (int i = 0; i < numberOfThreads; i++)
		{
			threadVector.emplace_back(thread(c_procedure, imagePixels, partsRanges[i].first, partsRanges[i].second,
				imageWidthCeil));
		}
	}


	//for (int i = 0; i < numberOfThreads; i++)
	//{
	//	threadVector[i].join();
	//}

	
	auto stop = chrono::steady_clock::now();

	auto timeElapsed = chrono::duration_cast<chrono::microseconds>(stop - start);// / 1000000.0;

	cout << endl;
	cout << "Time elapsed: " << timeElapsed.count() / 1000000.0 << " s" << endl;

	sendToTxt(numberOfThreads, timeElapsed.count(), useAsm);

	string imageFilename;

	if (useAsm)
	{
		imageFilename = "mandelbrot_asm.bmp";
	}
	else
	{
		imageFilename = "mandelbrot_C.bmp";
	}

	GenerateImageFromArray(imagePixels, imageWidth, imageHeight, imageFilename);

	ClearMemory(imagePixels, imageHeight);


	cout << endl << "Program ended <Press Enter>";
	cin.get();
	return 0;
}
