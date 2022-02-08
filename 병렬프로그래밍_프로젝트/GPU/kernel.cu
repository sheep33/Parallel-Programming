#include <stdlib.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include <vector>
#include <math.h>
#include <time.h>//초 재기
#include "..\usr\include\GL\freeglut.h"

using namespace std;

#define TILE_WIDTH 12
const int Dim = 972;//3의 5승 X 4 
unsigned char Image[Dim * Dim * 3];
unsigned char* Dev_Image;

int ManipulateMode = 0;
float Angle = 0.0;
//확대 축소를 위한 변수
int aa = 1;
int bb = 1;

//최소 사각형 크기와 같다
int limit;
//변화하는 무지개 배경 설정을 위한 변수
int Flow;

float Theta = 0.0;
int MaxIter = 256;
int StartPt[2];
float Zoom = -50.0;


vector <vector <int> > a;

unsigned char ColorTable[18];

// 콜백 함수
void Render();
void Reshape(int w, int h);
void Timer(int id);
void MouseWheel(int button, int dir, int x, int y);
void Keyboard(unsigned char key, int x, int y);


// 사용자 정의 함수
void CreateNemo();
__device__ void ColorNemo(int yy, int flow, int& r, int& g, int& b);
__global__ void NemoKernel(unsigned char* d, int li, int flow);
__int64 GetMicroSecond();


int main(int argc, char** argv)
{
	limit = Dim;
	// GLUT 초기화
	glutInit(&argc, argv);
	glutInitDisplayMode(GLUT_RGB);

	// 윈도우 크기 설정 및 생성
	glutInitWindowSize(Dim, Dim);
	glutCreateWindow("Sierpinski carpet(GPU)");
	cudaMalloc((void**)&Dev_Image, 3 * Dim * Dim * sizeof(unsigned char));

	// 콜백 함수 등록
	glutDisplayFunc(Render);
	glutMouseWheelFunc(MouseWheel);
	glutKeyboardFunc(Keyboard);
	glutReshapeFunc(Reshape);
	glutTimerFunc(1, Timer, 0);



	cudaSetDevice(0);

	// 이벤트 처리 루프 진입
	glutMainLoop();

	cudaFree(Dev_Image);
	cudaDeviceReset();
	return 0;
}

void Render()
{
	// 픽셀 버퍼(배경) 흰색으로 초기화
	glClearColor(1, 1, 1, 1);
	glClear(GL_COLOR_BUFFER_BIT);
	CreateNemo();
	glDrawPixels(Dim, Dim, GL_RGB, GL_UNSIGNED_BYTE, Image);

	glFinish();
}

void Timer(int id)
{
	// Render 함수를 호출하고, 다음 타이머를 설정한다.
	Flow += 3;//y축에 더해 색을 변경하기 위한 변수
	if (Flow > 972) {
		Flow = 0; //Dim크기 초과 시 다시 처음으로 되돌아 간다.
	}
	glutPostRedisplay();
	glutTimerFunc(1, Timer, 0);
}


__int64 GetMicroSecond()//시간측정
{
	LARGE_INTEGER frequency;
	LARGE_INTEGER now;

	if (!QueryPerformanceFrequency(&frequency))
		return (__int64)GetTickCount();

	if (!QueryPerformanceCounter(&now))
		return (__int64)GetTickCount();

	return ((now.QuadPart) / (frequency.QuadPart / 1000000));
}


void MouseWheel(int button, int dir, int x, int y)//화면 확대, 축소 함수
{
	if (dir > 0)
	{
		aa += 1;
		bb += 1;
		glPixelZoom(aa, bb);
	}
	else
	{

		aa -= 1;
		bb -= 1;
		if (aa < 1 || bb < 1)
		{
			aa = 1;
			bb = 1;
		}
		glPixelZoom(aa, bb);
	}
	glutPostRedisplay();
}

void Keyboard(unsigned char key, int x, int y)//키보드 조작 함수
{
	// ESC 키를 누르면 메쉬 리스트를 메모리에서 삭제하고 종료한다.
	if (key == 27)
		exit(0);

	//d 키를 누르면 단계 높히기
	if (key == 100)
	{
		if (limit >4)
		{
			limit = limit / 3;
		}
		glutPostRedisplay();//다시 그리기
	}
	//a키를 누르면 단계 낮추기
	if (key == 97)
	{
		if (limit < Dim)
			limit = limit * 3;
		glutPostRedisplay();//다시 그리기
	}

}

void Reshape(int w, int h)
{
	glViewport(0, 0, w, h);
}



void CreateNemo() {

	dim3 gridDim(Dim / TILE_WIDTH, Dim / TILE_WIDTH);//그리드 크기 정의
	dim3 blockDim(TILE_WIDTH, TILE_WIDTH);//블록 크기 정의
	__int64 st = GetMicroSecond();

	NemoKernel << <gridDim, blockDim >> > (Dev_Image, limit, Flow);//커널 함수 호출
	cudaDeviceSynchronize();//동기화
	cudaMemcpy(Image, Dev_Image, Dim * Dim * 3 * sizeof(unsigned char), cudaMemcpyDeviceToHost);//디바이스->호스트로 이미지배열 전달

	printf("Elapsed time = %u micro sec.\n", GetMicroSecond() - st);//경과시간 출력

}
__device__ void ColorNemo(int yy, int flow, int& r, int& g, int& b)/*흐르는 무지개 배경 설정을 위한 함수*/
{
	int ColorTable[18];//총 6개 색상의 RGB를 저장
					   //빨강
	ColorTable[0] = 225;//R
	ColorTable[1] = 102;//G
	ColorTable[2] = 99;//B
					   //파랑
	ColorTable[3] = 158;
	ColorTable[4] = 193;
	ColorTable[5] = 207;
	//초록
	ColorTable[6] = 158;
	ColorTable[7] = 224;
	ColorTable[8] = 158;
	//노랑
	ColorTable[9] = 253;
	ColorTable[10] = 253;
	ColorTable[11] = 151;
	//주황
	ColorTable[12] = 254;
	ColorTable[13] = 177;
	ColorTable[14] = 68;
	//보라
	ColorTable[15] = 204;
	ColorTable[16] = 153;
	ColorTable[17] = 201;

	float t = yy + flow;//t값은 각 스레드의 y좌표를 대변하는 변수로 계속해서 변하는 y좌표의 색상을 반영한다.
	if (t > 971) {//t가 Dim만큼 이동되었을 때
		t = flow - 971 + yy;//DIm을 초과하면 0~5사이 값으로 변환하지 못하므로 다시 처음으로 돌아간다.
	}
	t = t * 0.005;//0~5의 값으로 사상
				  //t값에 따라 각 색들을 보간해 무지개 형성
	if (t >= 0 && t < 1) {
		r = (int)(ColorTable[0] * (1 - t) + t * ColorTable[3]);
		g = (int)(ColorTable[1] * (1 - t) + t * ColorTable[4]);
		b = (int)(ColorTable[2] * (1 - t) + t * ColorTable[5]);
	}
	else if (t >= 1 && t < 2) {
		t = t - 1;
		r = (int)(ColorTable[3] * (1 - t) + t * ColorTable[6]);
		g = (int)(ColorTable[4] * (1 - t) + t * ColorTable[7]);
		b = (int)(ColorTable[5] * (1 - t) + t * ColorTable[8]);
	}
	else if (t >= 2 && t < 3) {
		t = t - 2;
		r = (int)(ColorTable[6] * (1 - t) + t * ColorTable[9]);
		g = (int)(ColorTable[7] * (1 - t) + t * ColorTable[10]);
		b = (int)(ColorTable[8] * (1 - t) + t * ColorTable[11]);
	}
	else if (t >= 3 && t < 4) {
		t = t - 3;
		r = (int)(ColorTable[9] * (1 - t) + t * ColorTable[12]);
		g = (int)(ColorTable[10] * (1 - t) + t * ColorTable[13]);
		b = (int)(ColorTable[11] * (1 - t) + t * ColorTable[14]);
	}
	else if (t >= 4 && t < 5) {
		t = t - 4;
		r = (int)(ColorTable[12] * (1 - t) + t * ColorTable[15]);
		g = (int)(ColorTable[13] * (1 - t) + t * ColorTable[16]);
		b = (int)(ColorTable[14] * (1 - t) + t * ColorTable[17]);
	}
	else {
		r = 255;
		g = 255;
		b = 255;
	}
}



__global__ void NemoKernel(unsigned char* d, int li, int flow)//시에르핀스키 사각형 구현 함수
{
	int x = blockIdx.x * TILE_WIDTH + threadIdx.x;
	int y = blockIdx.y * TILE_WIDTH + threadIdx.y;
	int size = Dim;



	if ((x < Dim) && (y < Dim))//Color Nemo를 이용한 배경색 채우기
	{
		int rr, gg, bb;
		ColorNemo(y, flow, rr, gg, bb);
		int offset = (y * Dim + x) * 3;
		d[offset] = rr;
		d[offset + 1] = gg;
		d[offset + 2] = bb;
	}
	while (size >= li)//각 단계마다(li=limit=4=최소 사각형 한변의 픽셀 수)
	{
		size = size / 3;//사각형의 한변을 3등분한다. 
		if (size == 1) {//최대 단계인 경우이다. 최소 사각형의 한변은 3의 배수가 아니므로 3등분이 불가능해 따로 계산해 준다.
			if ((((x / size) % 4 == 1) || ((x / size) % 4 == 2)) && (((y / size) % 4 == 1) || ((y / size) % 4 == 2)))/*3등분된 사각형들 중 정 중앙
																													 에 위치한 사각형을 채우는 쓰레드일 경우*/
			{
				int offset2 = (x + y * Dim) * 3;
				d[offset2] = 235;
				d[offset2 + 1] = 230;
				d[offset2 + 2] = 204;
			}
		}
		else if (((x / size) % 3 == 1) && ((y / size) % 3 == 1)) {/*최대 단계를 제외한 경우이다. 현재 쓰레드 인덱스(위치)를 size로 나누어 3으로
																  나누었을 때의 나머지가 1인 스레드는 정중앙의 사각형을 채우는 쓰레드이다*/
			int offset2 = (x + y * Dim) * 3;
			d[offset2] = 235;
			d[offset2 + 1] = 230;
			d[offset2 + 2] = 204;

		}
	}
}