#include <stdio.h>
const int MaximumIterations = 50;


int mandelbrotPixelTest(float, float);

const float	X1 = -2.0f;
const float	X2 = 1.0f;
const float	Y1 = -1.0f;
const float	Y2 = 1.0f;


void MandelbrotTest_C(unsigned char ** pixelArray, int begin_line, int line_length, int columns)
{
	float precisionPerPixel = (X2 - X1) / columns;

	for (int i = begin_line; i < begin_line + line_length; i++)
	{
		for (int j = 0; j < columns; j++)
		{
			// Set proper complex value
			float p_re = X1 + j * precisionPerPixel;
			float p_im = Y1 + i * precisionPerPixel;

			// Test the value 
			int testResult = mandelbrotPixelTest(p_re, p_im);

			// Set pixel color saturation according to the result
			pixelArray[i][j] = (unsigned char)(255 * (1 - testResult / (float)MaximumIterations));

			/*if (testResult == MaximumIterations)
			{
				pixelArray[i][j] = 250;
			}
			else
			{
				pixelArray[i][j] = (unsigned char)(255 * (1 - testResult / (float)MaximumIterations));
			}*/
		}
	}

	return;
}

//Complex Function(Complex Z, Complex P)
//{
//	Complex res;
//	// Z^2 + P = a_z^2 - b_z^2 + 2i*a_z*b_z + a_p + ib_p
//
//	res.Re = Z.Re * Z.Re - Z.Im * Z.Im + P.Re;
//	res.Im = 2 * Z.Re * Z.Im + P.Im;
//
//	return res;
//}

// Simpler form of the function

float funcRe(float z_re, float z_im, float p_re)
{
	return z_re * z_re - z_im * z_im + p_re;
}

float funcIm(float z_re, float z_im, float p_im)
{
	return 2.f * z_re * z_im + p_im;
}


int mandelbrotPixelTest(float p_re, float p_im)
{
	float z_re = 0.f;
	float z_im = 0.f;
	float z_re2 = 0.f;
	float z_im2 = 0.f;

	int iterations = 0;
	float z_norm = 0.f;
	while (iterations < MaximumIterations && z_norm < 4.f)
	{
		float z_re_New = z_re2 - z_im2 + p_re;
		z_im = 2.f * z_re * z_im + p_im;
		z_re = z_re_New;
		z_re2 = z_re * z_re;
		z_im2 = z_im * z_im;
		iterations++;
		z_norm = z_re2 + z_im2;

		// Old version
		/*float z_re_New = funcRe(z_re, z_im, p_re);
		z_im = funcIm(z_re, z_im, p_im);
		z_re = z_re_New;
		iterations++;
		z_norm = z_re * z_re + z_im * z_im;*/
	}
	return iterations;
}