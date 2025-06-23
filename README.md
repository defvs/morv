# MORV

A simple 32-bit RISC-V processor (RV32I) written in SystemVerilog.

## Overview

This project is a basic implementation of the RV32I instruction set architecture. The processor is implemented in a single module, `morv_top`, and is not pipelined.

I am intending on building upon this to learn how to make RISC-V CPUs.

## Features

*   Implements the base integer instruction set (RV32I).
*   Single-cycle instruction execution (excluding memory access).
*   Simple memory interface.
