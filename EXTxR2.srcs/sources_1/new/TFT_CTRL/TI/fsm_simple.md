# TI_TFT_CTRL State Machines - Simple Version
# Copy the mermaid code blocks below into https://mermaid.live to view diagrams

## 1. state_grab - Grab Control FSM

```mermaid
stateDiagram-v2
    [*] --> IDLE
    IDLE --> DATA : grab_en_tmp ON
    DATA --> IDLE : grab_en OFF or frame done
    DATA --> IDLE : frame_num reached
    IDLE --> IDLE : no trigger
```

## 2. state_tft - TFT Main FSM

```mermaid
stateDiagram-v2
    [*] --> IDLE

    IDLE --> TRST : No grab, Reset mode 0
    IDLE --> SRST_EWT : No grab, Reset mode 1
    IDLE --> EWT : Grab with Shutter or Trigger
    IDLE --> SCAN : Grab Rolling, no reset
    IDLE --> GRST : D2M GRST select

    TRST --> IDLE : rst_cycle done
    SRST_EWT --> SRST : exp_time reached
    SRST --> RstFrWait : gate and roic done
    GRST --> IDLE : gate GRST_GEnd

    EWT --> SCAN : exp_time reached
    EWT --> FINISH : grab stop or bcal

    SCAN --> ScanFrWait : gate and roic done
    ScanFrWait --> FINISH : frame_time reached
    RstFrWait --> RstFINISH : frame_time reached

    FINISH --> IDLE
    RstFINISH --> IDLE
```

## 3. state_roic - ROIC Readout FSM

```mermaid
stateDiagram-v2
    [*] --> IDLE
    IDLE --> OFFSET : tft is SCAN or SRST
    OFFSET --> DUMMY : gate is READY
    DUMMY --> INTRST
    INTRST --> CDS1 : intrst_time done
    CDS1 --> GATE_OPEN : cds1_time done
    GATE_OPEN --> CDS2 : immediate
    CDS2 --> LDEAD : cds2_time done
    LDEAD --> DUMMY : more lines remain
    LDEAD --> FWAIT : all lines done
    FWAIT --> IDLE : tft is IDLE
```

## 4. state_gate - Gate Drive FSM

```mermaid
stateDiagram-v2
    [*] --> IDLE

    IDLE --> DIO_CPV : tft SCAN or SRST, with offset
    IDLE --> READY : tft SCAN or SRST, no offset
    IDLE --> XON : tft is TRST
    IDLE --> GRST_G : tft is GRST

    READY --> DIO_CPV : roic GATE_OPEN, ch 0
    READY --> CPV : roic GATE_OPEN, ch above 0

    DIO_CPV --> OE : CPV sequence done
    DIO_CPV --> DUMMY : dummy mode
    CPV --> OE : CPV done
    CPV --> DUMMY : dummy mode

    OE --> CHECK : oe_time done

    CHECK --> LWAIT : more lines
    CHECK --> OE_READY : multi OE
    CHECK --> FWAIT : all done or TRST

    OE_READY --> DIO_CPV : ch 0
    OE_READY --> CPV : ch above 0

    LWAIT --> READY : roic DUMMY, no dummy_en
    LWAIT --> CPV : roic DUMMY, dummy_en

    DUMMY --> DIO_CPV : more dummy lines
    DUMMY --> READY : dummy done
    DUMMY --> FWAIT : end flag set

    XON --> XON_FLK : xon partial done
    XON_FLK --> FLK : xon done
    FLK --> CHECK : flk done

    GRST_G --> GRST_GEnd : V count done
    GRST_GEnd --> IDLE

    FWAIT --> IDLE : tft is IDLE
```

## 5. state_d2m - D2M Sub FSM, inside state_tft

```mermaid
stateDiagram-v2
    [*] --> idle
    idle --> xray_start : d2m trigger input
    xray_start --> xray
    xray --> xrayrst
    xrayrst --> xrayrst : xrst count not done
    xrayrst --> dark_start : xrst done
    dark_start --> dark
    dark --> darkrst
    darkrst --> darkrst : drst count not done
    darkrst --> end_state : drst done
    end_state --> idle
```
