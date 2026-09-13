# SIH-project-prototype
Adaptive path planning and collision avoidance system for autonomous vehicles navigating unstructured Indian roads, simulated in MATLAB/Simulink with RoadRunner scenario design.
# Adaptive Path Planning and Collision Avoidance for Autonomous Vehicles on Unstructured Indian Roads

> Smart India Hackathon (SIH) Project

## 📌 Problem Statement

Most autonomous driving systems are built for roads with clear lane markings, standard signage, and predictable traffic flow. Indian roads are different — mixed traffic (cars, buses, auto-rickshaws, two-wheelers, pushcarts, pedestrians, and animals), unclear road edges, potholes, and informal driving behavior make traditional structured path-planning approaches unreliable.

This project designs and simulates an **adaptive path planning system** for an autonomous vehicle that can perceive, predict, and safely navigate unstructured, mixed-traffic Indian road conditions in real time.

## 🎯 Objective

Build a closed-loop simulation pipeline that:
- Perceives the environment via a multi-sensor setup (camera, LiDAR, radar)
- Detects and classifies diverse road users and obstacles
- Predicts short-term, non-lane-based motion of surrounding agents
- Generates a safe, collision-free path with real-time replanning
- Handles missing lane markings, informal merging, sudden pedestrian movement, and unexpected obstacles

## 🧩 System Architecture

```
Sensors (Camera / LiDAR / Radar)
        │
        ▼
   Perception Module ──► Object Detection & Classification
        │
        ▼
   Prediction Module ──► Short-term Trajectory Forecasting
        │
        ▼
   Path Planning ──► Collision-free Trajectory Generation
        │
        ▼
   Decision Logic (Stateflow) ──► Behavior Selection
        │
        ▼
   Vehicle Dynamics (Bicycle Model) ──► Motion Execution
```

## 🛠️ Tech Stack

| Component | Tool |
|---|---|
| Scenario Design | MathWorks RoadRunner |
| Sensor Modeling & Fusion | Automated Driving Toolbox |
| Planning & Decision Logic | Navigation Toolbox, Stateflow |
| Vehicle Behavior | Vehicle Dynamics Blockset / Simulink Bicycle Model |
| Detection & Trajectory Prediction | Deep Learning Toolbox |
| Simulation Environment | MATLAB / Simulink |

## 🧪 Test Scenarios

The system is validated across five realistic Indian road scenarios:

1. **Unmarked village road** — no lane markings, irregular road edges
2. **Busy urban intersection without signals** — informal merging, mixed traffic
3. **Highway merge with slow-moving vehicles** — speed differential handling
4. **Dense market area** — high pedestrian and vendor density
5. **Sudden cattle-crossing event** — unpredictable obstacle response

Two of these (village road, urban intersection) are built as detailed RoadRunner scenes.

## 📊 Performance Metrics

- Replanning latency
- Path smoothness
- Scenario completion rate
- Collision-free performance across all scenarios

## 📁 Repository Structure

```
├── models/                # Simulink models (perception, planning, control)
├── scenarios/             # RoadRunner scene files
├── scripts/               # MATLAB scripts for setup, analysis, metrics
├── results/               # Simulation outputs, plots, logs
├── docs/
│   ├── technical_report.pdf
│   └── demo_video_link.md
└── README.md
```

## 🚀 Getting Started

### Prerequisites
- MATLAB R2023b or later
- Simulink
- Automated Driving Toolbox
- Navigation Toolbox
- Deep Learning Toolbox
- Vehicle Dynamics Blockset
- RoadRunner (for scenario editing)

### Setup
```bash
git clone https://github.com/<your-username>/<repo-name>.git
cd <repo-name>
```

Open MATLAB, navigate to the project folder, and run:
```matlab
setupProject.m
```

### Running a Scenario
```matlab
runScenario('village_road')
```
Replace `'village_road'` with any of: `urban_intersection`, `highway_merge`, `market_area`, `cattle_crossing`.

## 📹 Demo

A demonstration video showing the vehicle navigating all test scenarios is available [here](#) *(add link)*.

## 📄 Technical Report

Full methodology, design decisions, and results are documented in [`docs/technical_report.pdf`](docs/technical_report.pdf).

## 👥 Team

| Name | Role |
|---|---|
| — | Perception & Sensor Fusion |
| — | Path Planning |
| — | Vehicle Dynamics & Control |
| — | Scenario Design (RoadRunner) |
| — | Documentation & Testing |

## 📜 License

This project is submitted as part of Smart India Hackathon (SIH) and is intended for academic and research purposes.
