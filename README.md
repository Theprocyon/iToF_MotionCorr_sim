# iToF_MotionCorr_sim

## 📌 프로젝트 개요

**iToF_MotionCorr_sim**은 Indirect Time-of-Flight (iToF) 카메라의 동작을 시뮬레이션하는 MATLAB 기반 프로젝트입니다.  
이 프로젝트의 최종 목표는 **Motion이 심한 환경에서 각 correlation 이미지들이 서로 다른 장면을 포착하는 문제**를 해결하기 위한 기반 시뮬레이터를 구축하는 것이며,  
이후 Optical Flow 기반의 보정 알고리즘 논문 작성으로 확장될 예정입니다.

---

## 🛠️ 주요 기능 및 구성

### 1. **iToF 시뮬레이션**
- `src/sim/itof_sim.m`  
  ⤷ 전체 시뮬레이션을 실행하는 메인 스크립트  
- `src/sim/itof_sim_param.m`  
  ⤷ 시뮬레이션 설정 (변조 주파수, 노출 시간, 광 세기 등)

### 2. **코어 기능**
- `itof_corr.m`  
  ⤷ iToF 카메라의 N-phase correlation 이미지 생성  
- `itof_depth_est_from_corr.m`  
  ⤷ Correlation 이미지로부터 위상 복원 및 depth 계산  
- `itof_inten_est_from_corr.m`  
  ⤷ Correlation 이미지로부터 intensity 추정  
- `itof_rgb2albedo.m`  
  ⤷ RGB 이미지를 이용해 albedo map 생성 (0~1 정규화)

---

## 📂 폴더 구조

```
iToF_MotionCorr_sim/
├── src/
│   └── sim/             # 주요 시뮬레이션 코드
├── resources/           # RGB 및 Depth 입력 이미지
├── lib/                 # Optical flow 등 향후 확장 기능
├── .gitignore
```

---

## ✅ 사용 방법

```matlab
run('src/sim/itof_sim.m')
```

- 시뮬레이션은 `SimConfig.SingleFrameMode`에 따라 하나의 프레임 또는 전체에 대해 실행됩니다.
- 최종적으로 다음 결과들이 시각화됩니다:
  - Raw RGB, Raw Depth
  - Correlation images (N개)
  - 추정된 Depth
  - 추정된 Intensity
  - GT Depth와의 차이 (오차 맵)
