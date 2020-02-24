.data
k8 real8   1072632447.0
w8 real8   9076650.0
.code

;gamma(x) = 255* pow (x/255, 1/g)
;t = pow (x/255, 1/g)
;t = (x - 1) * w / (x + 1 + 4 * sqrt(x)) * b + k, 
    ;potem trzeba jeszcze wykonaæ << 32 i cast do (double)
;s = (x + 1 + 4 * sqrt(x))
;t = (x - 1) * w / s * b + k
;k = 1072632447.0
;w = 9076650.0

gammaAVXasm proc 
;rcx - gammaTab
;xmm1 - gamma
;r8 - id
  add rcx, r8 ;przesunac wskaznik
  vpcmpeqw ymm0, ymm0, ymm0
  vpsllq   ymm0, ymm0, 54
  vpsrlq   ymm0, ymm0, 2
  ;ymm0 - 1,1,1,1

  vmovapd ymm4, ymm0
  ;ymm4 - 1,1,1,1
  vaddpd ymm5, ymm4, ymm4 ;ymm5  = ymm4 * 2
  vaddpd ymm5, ymm5, ymm5 ;ymm5 += ymm5 (=x2)
  ;ymm5 - 4,4,4,4 (float)
  vaddpd ymm8, ymm5, ymm5 ;ymm8 = 2*ymm5
  vaddpd ymm8, ymm8, ymm8 ;ymm8 += ymm8 (=x2)
  vaddpd ymm8, ymm8, ymm8 ;ymm8 += ymm8 (=x2)
  vaddpd ymm8, ymm8, ymm8 ;ymm8 += ymm8 (=x2)
  vaddpd ymm8, ymm8, ymm8 ;ymm8 += ymm8 (=x2)
  vaddpd ymm8, ymm8, ymm8 ;ymm8 += ymm8 (=x2)
  ;ymm8 - 256,256,256,256
  vsubpd ymm8, ymm8, ymm0
  ;ymm8 - 255,255,255,255
  vbroadcastsd ymm1, xmm1 ;wsadza dolny xmm1 na cztery pola ymm1
  ;ymm1 - g,g,g,g
  vdivpd ymm1, ymm0, ymm1
  ;ymm1 - b,b,b,b (1/g = b w pow(a,b))
  movsd xmm3, k8
  vbroadcastsd ymm3, xmm3 ;wsadza dolny xmm3 na cztery pola ymm3
  ;ymm3 - k,k,k,k
  movsd xmm2, w8
  vbroadcastsd ymm2, xmm2 ;wsadza dolny xmm2 na cztery pola ymm2
  ;ymm2 - w,w,w,w
  
  vxorpd ymm6, ymm6, ymm6 ;ymm6 - 0,0,0,0
  vxorpd ymm0, ymm0, ymm0 ;ymm0 - 0,0,0,0
  vshufpd ymm6, ymm4, ymm6, 0000b
  ;ymm6 - 0,1,0,1
  movapd xmm0, xmm4
  ;ymm0 - 0,0,1,1
  addpd xmm0, xmm4
  ;ymm0 - 0,0,2,2
  vaddpd ymm0, ymm6, ymm0
  ;ymm0 - 0,1,2,3 
  movd xmm7, r8d
  cvtdq2pd xmm7, xmm7
  vbroadcastsd ymm7, xmm7
  vaddpd ymm0, ymm0, ymm7

  vdivpd ymm0, ymm0, ymm8
  ;ymm0 - x0/255,...,x3/255

  ;s = (x+1+4*sqrt(x))
  vsqrtpd ymm6, ymm0 
  ;ymm6 - sqrt(x),...
  vmulpd ymm6, ymm5, ymm6
  ;ymm6 - 4*sqrt(x),...
  vaddpd ymm6, ymm0, ymm6
  ;ymm6 - x + 4*sqrt(x),...
  vaddpd ymm6, ymm4, ymm6
  ;ymm6 - s0,s1,s2,s3 - x+1+4*sqrt(x)


  vsubpd  ymm0, ymm0, ymm4
  ;ymm0 - x-1,...
  vmulpd  ymm0, ymm2, ymm0
  ;ymm0 - (x-1)*w,...
  vdivpd  ymm0, ymm0, ymm6
  ;ymm0 - (x-1)*w/s,...
  vmulpd  ymm0, ymm1, ymm0
  ;ymm0 - (x-1) * w / s * b,...
  vaddpd  ymm0, ymm3, ymm0
  ;ymm0 - (x-1) * w / s * b + k,...  - t0,t1,t2,t3

  vcvtpd2dq xmm0, ymm0 ;zamieñ 4 double na 4 int  ;1,2,3,4
  ;xmm0 - int0,int1,int2,int3           
  vpmovzxdq ymm0, xmm0 ;rozszerz xmm do ymm
  ;ymm0 - 0,int0, 0,int1, 0,int2, 0,int3
  vpslldq   ymm0, ymm0, 4h ;przesuñ wszystkie inty <<32 (tym samym zamieniaj¹c je bitowo w double)
  ;ymm0 - pow(x0,1/g),pow(x1,1/g),pow(x2,1/g),pow(x3,1/g)
  ;ymm0 - t0,t1,t2,t3

  vmulpd ymm0, ymm8, ymm0
  ;vmovapd ymm6, ymm0
  ;ymm6 - t0,t1,t2,t3
  ;{
  ;vmulpd  ymm0, ymm5, ymm0
  ;vmulpd  ymm0, ymm5, ymm0
  ;vmulpd  ymm0, ymm5, ymm0
  ;vmulpd  ymm0, ymm5, ymm0
  ;} *256  (*4*4*4*4)
  ;ymm0 - 256*pow(x)
  ;vsubpd  ymm0, ymm0, ymm6
  ;ymm0 - 256*pow(x) - pow(x)
  ;ymm0 - 255*pow(x)

  ;zapis do pamiêci
  vcvtpd2dq xmm0, ymm0 ;zamieñ 4 double na 4 int  ;1,2,3,4
  movd eax, xmm0 
  ;eax - 0004
  shl eax, 8
  ;eax - 0040
  shufps xmm0, xmm0, 00111001b
  ;xmm0 - 4123
  movd edx, xmm0
  add eax, edx
  ;eax - 0043
  shl eax, 8
  ;eax - 0430
  shufps xmm0, xmm0, 00111001b
  ;xmm0 - 3412
  movd edx, xmm0
  ;edx - 0002
  add eax, edx
  ;eax - 0432
  shl eax, 8
  ;eax - 4320
  shufps xmm0, xmm0, 00111001b
  ;xmm0 - 2341
  movd edx, xmm0
  ;edx - 0001
  add eax, edx
  ;eax - 4321 - wpisywane od koñca
  
  mov dword ptr[rcx], eax

  ret
gammaAVXasm endp
end