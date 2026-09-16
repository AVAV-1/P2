```python
# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):

    dut._log.info("Start IIR Biquad Filter Test")

    # ============================================================
    # Clock
    # 10 us period = 100 KHz
    # ============================================================

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())


    # ============================================================
    # RESET
    # ============================================================

    dut._log.info("Reset")

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)

    dut.rst_n.value = 1

    await ClockCycles(dut.clk, 1)


    # ============================================================
    # CHECK RESET OUTPUT
    # ============================================================

    dut._log.info("Checking reset output")

    assert dut.uo_out.value.signed_integer == 0, \
        "Output is not zero after reset"


    # ============================================================
    # IMPULSE RESPONSE
    # ============================================================

    dut._log.info("----------------------------------------")
    dut._log.info("IIR BIQUAD IMPULSE RESPONSE")
    dut._log.info("----------------------------------------")


    # ------------------------------------------------------------
    # Apply impulse
    # ------------------------------------------------------------

    dut.ui_in.value = 100

    await ClockCycles(dut.clk, 1)

    output = dut.uo_out.value.signed_integer

    dut._log.info(
        "Input = %d, Output = %d",
        100,
        output
    )


    # ------------------------------------------------------------
    # Remaining samples = 0
    # ------------------------------------------------------------

    dut.ui_in.value = 0

    for i in range(10):

        await ClockCycles(dut.clk, 1)

        output = dut.uo_out.value.signed_integer

        dut._log.info(
            "Sample %d: Input = %d, Output = %d",
            i + 1,
            0,
            output
        )


    # ============================================================
    # TEST MULTIPLE INPUT VALUES
    # ============================================================

    dut._log.info("----------------------------------------")
    dut._log.info("TESTING MULTIPLE INPUT SAMPLES")
    dut._log.info("----------------------------------------")


    test_inputs = [
        10,
        20,
        30,
        40,
        50,
        0,
        0,
        0
    ]


    for sample in test_inputs:

        dut.ui_in.value = sample

        await ClockCycles(dut.clk, 1)

        output = dut.uo_out.value.signed_integer

        dut._log.info(
            "Input = %d, Output = %d",
            sample,
            output
        )


    # ============================================================
    # DISABLE ENABLE SIGNAL
    # ============================================================

    dut._log.info("----------------------------------------")
    dut._log.info("Testing ENA signal")
    dut._log.info("----------------------------------------")

    dut.ena.value = 0
    dut.ui_in.value = 100

    await ClockCycles(dut.clk, 1)

    output = dut.uo_out.value.integer

    dut._log.info(
        "ENA = 0, Output = %d",
        output
    )

    assert output == 0, \
        "Output should be zero when ENA is disabled"


    # ============================================================
    # ENABLE AGAIN
    # ============================================================

    dut.ena.value = 1

    dut.ui_in.value = 0

    await ClockCycles(dut.clk, 1)

    output = dut.uo_out.value.signed_integer

    dut._log.info(
        "ENA = 1, Input = 0, Output = %d",
        output
    )


    # ============================================================
    # FINAL RESET
    # ============================================================

    dut._log.info("----------------------------------------")
    dut._log.info("Final reset")
    dut._log.info("----------------------------------------")

    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 2)

    output = dut.uo_out.value.signed_integer

    dut._log.info(
        "After reset: Output = %d",
        output
    )

    assert output == 0, \
        "Output should be zero after reset"


    # ============================================================
    # COMPLETE
    # ============================================================

    dut.rst_n.value = 1

    dut._log.info("----------------------------------------")
    dut._log.info("IIR Biquad Test Completed")
    dut._log.info("----------------------------------------")
