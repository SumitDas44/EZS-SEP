# EZS-SEP
A Hybrid Efficient Zonal Stable Election Routing Protocol with SOM-Based Node Deployment for Heterogeneous Wireless Sensor Networks

This repository contains the MATLAB implementation of the **Efficient Zonal Stable Election Protocol with SOM-Based node deployment (EZS-SEP)** for heterogeneous Wireless Sensor Networks (WSNs).

The implementation accompanies the paper:

> **EZS-SEP: A Hybrid Efficient Zonal Stable Election Routing Protocol with SOM-Based Node Deployment for Heterogeneous Wireless Sensor Networks**
>
> Authors: Sumit Das, Md. Khorshed Alom
>
> (journal name, year, and DOI)

---

## Features

- Self-Organizing Map (SOM)-based node deployment
- Three-level heterogeneous network
- Multi-factor cluster head (CH) selection based on:
  - Initial energy
  - Residual energy
  - Average network energy
  - Distance to the Base Station
- Hybrid data transmission strategy
- Performance comparison with existing routing protocols
- Performance evaluation under different network scenarios

---

## Requirements

- MATLAB R2022a or later (or the version you used)
- Deep Learning Toolbox / Neural Network Toolbox (required for `selforgmap`)
- No additional third-party libraries are required.

---

## Repository Structure

```
EZS-SEP/
│
├── EZS_SEP.m              % Main simulation file
├── Datasets/              % Simulation results
├── LICENSE
└── README.md
```

---

## Running the Simulation

1. Open MATLAB.
2. Open the project folder.
3. Run:

```matlab
EZS_SEP.m
```

The script generates:

- Alive nodes vs. rounds
- Dead nodes vs. rounds
- Throughput (Packets to BS)
- Remaining energy
- Energy percentage

---

## Simulation Parameters

| Parameter | Value |
|-----------|------:|
| Network Size | 100 × 100 m² |
| Number of Nodes | 100 |
| Initial Energy | 0.5 J |
| Advanced Nodes | 20% |
| Intermediate Nodes | 30% |
| Packet Size | 4000 bits |
| Base Station | (50,50) |

These values can be modified directly in the MATLAB script.

---

## Citation

If you use this code, please cite:

```text
(after publication)
```

---

## License

This project is distributed under the MIT License. See the LICENSE file for details.

---
