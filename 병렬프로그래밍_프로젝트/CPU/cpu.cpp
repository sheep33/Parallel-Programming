#include <stdlib.h>
#include<iostream>
#include <vector>
#include <math.h>
#include <time.h>//초 재기
#include "..\usr\include\GL\freeglut.h"

using namespace std;
int StartPt[2];
float Zoom = -50.0;
int ManipulateMode = 0;
int aa = 1;
int bb = 1;//확대 축소를 위한 변수

__int64 GetMicroSecond();

const int Dim = 972;//3의 5승 곱하기 4->최소 픽셀은 4x4가 되고, 단계는 기본 단계까지 합해서 총 6단계가 된다.
int limit = Dim;//단계를 제한 할 변수. 키보드 이벤트로 조절 가능하다.

unsigned char Image[Dim * Dim * 3];//이미지 배열 선언



vector <vector <int> > a;// 단계별로 만들어지는 사각형들의 왼쪽 위 정점을 저장할 이차원 벡터.
//이 벡터는 (x좌표, y좌표, size 크기)의 배열로 이루어져 있다.

// 콜백 함수
void Render();
void Reshape(int w, int h);
void MouseWheel(int button, int dir, int x, int y);
void Keyboard(unsigned char key, int x, int y);


// 사용자 정의 함수
void Nemo();//시에르핀스키 카펫을 구현해주는 함수

int main(int argc, char** argv)
{
    // GLUT 초기화
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_RGB);

    // 윈도우 크기 설정 및 생성
    glutInitWindowSize(Dim, Dim);
    glutCreateWindow("Sierpinski carpet");

    // 콜백 함수 등록
    glutDisplayFunc(Render);
    glutMouseWheelFunc(MouseWheel);
    glutKeyboardFunc(Keyboard);
    glutReshapeFunc(Reshape);

    // 이벤트 처리 루프 진입
    glutMainLoop();

    return 0;
}

void Render()
{
    // 픽셀 버퍼(배경) 흰색으로 초기화
    glClearColor(1, 1, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT);

    Nemo();//시에르핀스키 구현 함수를 실행한다.

    glDrawPixels(Dim, Dim, GL_RGB, GL_UNSIGNED_BYTE, Image); //이미지 픽셀을 그린다.

    glFinish();

}





void MouseWheel(int button, int dir, int x, int y)
{
    if (dir > 0)
    {
        aa += 1;
        bb += 1;
        glPixelZoom(aa, bb);//마우스로 휠을 위로 움직이면 확대를 한다.
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
        glPixelZoom(aa, bb);//마우스로 휠을 아래로 움직이면 축소를 한다.
    }
    glutPostRedisplay();//변화를 주었기 때문에 다시그린다.
}

void Keyboard(unsigned char key, int x, int y)
{
    // ESC 키를 누르면 메쉬 리스트를 메모리에서 삭제하고 종료한다.
    if (key == 27)
        exit(0);
    //d 키를 누르면 단계 높히기
    if (key == 100) {
        if(limit>4)
            limit = limit / 3;
        glutPostRedisplay();//다시 그리기

    }
    //a키를 누르면 단계 낮추기
    if (key == 97) {
        if (limit < Dim)
            limit = limit * 3;//항상 사각형을 3등분하면서 진행하기 때문에 단계로 3씩 올리고 낮춰야 한다.
        glutPostRedisplay();//다시 그리기

    }

}

void Reshape(int w, int h)
{
    glViewport(0, 0, w, h);
}


void Nemo()
{
    __int64 st = GetMicroSecond();

    //배경색을 하얗게 초기화 해준다.
    for (int j = 0; j < Dim; ++j) {
        for (int i = 0; i < Dim; ++i) {
            int offset = (j * Dim + i) * 3;
            Image[offset] = 255;
            Image[offset + 1] = 255;
            Image[offset + 2] = 255;
        }
    }
    a.clear();//벡터를 초기화해준다.
    //Dim은 전역변수
    int size = Dim;//처음 size는 Dim인 972
    int x = 0;//처음 상태인 972x972사각형의 왼쪽 위 좌표를 저장해준다.
    int y = 0;
    int max = 1;//while문 안의 for문에서 단계적으로 8씩 곱해가면서 반복하게 하는 변수 
    vector <int> vec;//원점과, 원사이즈를 푸쉬백해줄 임시 벡터
    vec.push_back(0);
    vec.push_back(0);
    vec.push_back(size);
    a.push_back(vec);//첫번째 점을 a 벡터에 저장해준다

    while (size >= limit) {//limit가 size보다 작거나 같게 함으로써 제한을 둔 이상으로는 단계를 진행하지 않도록 한다.

        size = size / 3;//가운데 사각형의 한 변의 길이는 큰 사각형의 한변의 길이의 3분의 1이다. 가운데 사각형을 그리기 위해서 size를 줄여준다.
        int num = a.size();//현재 벡터의 크기
        for (int i = num - max; i < num; i++) {
            x = a[i][0];
            y = a[i][1];//x, y좌표를 현재 a벡터의 정점으로 만들어준다. 정점을 기준으로 가운데 사각형을 색칠하기 때문이다.
            for (int j = 0; j < 9; j++) {//똑같은 크기로 9등분 된 사각형들의 인덱스 개수 만큼 반복해준다.
                vector <int> temp;
                if (j != 4) {//가운데 사각형이 아니라면 다음 정점에 넣어준다.
                    //x,y를 벡터로 설정해야함
                    temp.push_back(x + (j % 3) * size);
                    temp.push_back(y + (j / 3) * size);
                    temp.push_back(size);
                    a.push_back(temp);
                }
                if (j == 4) {//가운데 사각형이라면 랜덤한 색깔로 칠해준다.
                    int R, G, B;
                    R = rand() % 256;
                    G = rand() % 256;
                    B = rand() % 256;
                    //가운데 사각형의 x좌표= 정점의 x +size,
                    //가운데 사각형의 y좌표=정점의 y +size
                    //가운데 사각형의 정점을 기준으로 해서 x축으로 size만큼, y축으로 size만큼 채워준다. 
                    for (int a = y + size; a < size * 2 + y; ++a) {
                        for (int b = x + size; b < size * 2 + x; ++b) {
                            int offset = (a * Dim + b) * 3;
                            Image[offset] = R;
                            Image[offset + 1] = G;
                            Image[offset + 2] = B;
                        }
                    }
                }
            }
            //max(8의 제곱)개씩 푸쉬백
        }
        max = max * 8;//이전 단계보다 증가한 값으로 설정해준다.
    }

    printf("Elapsed time = %u us\n", GetMicroSecond() - st);//시간 재기 끝

}
__int64 GetMicroSecond()//마이크로세컨드로 시간 재기
{
    LARGE_INTEGER frequency;
    LARGE_INTEGER now;

    if (!QueryPerformanceFrequency(&frequency))
        return (__int64)GetTickCount();

    if (!QueryPerformanceCounter(&now))
        return (__int64)GetTickCount();

    return ((now.QuadPart) / (frequency.QuadPart / 1000000));
}
