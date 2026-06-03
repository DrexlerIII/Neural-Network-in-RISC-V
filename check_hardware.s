# a0 = ebp equivalent (v_config base)
# t-registers used for temporary math

Get_Hardware_Tjunction_Advanced:
    # --- 1. THE AUTHORITY CHECK ---
    # RISC-V equivalent of MSR_PLATFORM_INFO. 
    # We'll use a placeholder CSR (0xC01) often used for platform caps.
    csrr    t0, 0xC01           # Read Platform Info CSR
    li      t1, 0x40000000      # Bit 30: TCC Locked bit
    and     t2, t0, t1
    snez    t2, t2              # Set t2 to 1 if bit 30 is NOT zero
    sb      t2, offset_b_TCC_Locked(a0)

    # --- 2. PRIMARY SENSE (Tjunction Ceiling) ---
    # Read Thermal Target CSR (0xC02)
    csrr    t0, 0xC02           
    srli    t1, t0, 16          # shr eax, 16
    andi    t1, t1, 0xFF        # and eax, 0xFF (Tjunction value)
    
    # Sanity check (70C - 110C)
    li      t3, 70
    blt     t1, t3, _fallback_signature
    li      t3, 110
    bgt     t1, t3, _fallback_signature
    mv      a1, t1              # Valid Tjunction in a1
    j       _program_interlock

_fallback_signature:
    # On RISC-V, we check 'mvendorid' or 'marchid' instead of CPUID
    csrr    t0, mvendorid
    # Default to 100C for unknown high-performance silicon
    li      a1, 100

_program_interlock:
    sw      a1, offset_v_Tjunction(a0) # Commit the discovered ceiling

    # --- 3. HARDWARE TRIPWIRE PROGRAMMING ---
    # Read current Thermal Interrupt Config (0xC04)
    csrr    t0, 0xC04
    
    # Clear existing thresholds (Masking bits 8-15 and 16-23)
    # x86: and eax, 0FF8080FFh
    li      t1, 0xFF8080FF
    and     t0, t0, t1

    # --- STAGE 1: THE WARNING WALL (80°C) ---
    # Logic: Tjunction - 80 = Offset
    li      t2, 80
    sub     t3, a1, t2          # t3 = Tjunction - 80
    bltz    t3, _critical_thermal_abort # JS equivalent
    
    slli    t4, t3, 8           # Position into Bits 14:8
    or      t0, t0, t4
    ori     t0, t0, 0x8000      # Bit 15: Enable Threshold #1

    # --- STAGE 2: THE PANIC WALL (90°C) ---
    # Logic: Tjunction - 90 = Offset
    li      t2, 90
    sub     t3, a1, t2          # t3 = Tjunction - 90
    bltz    t3, _critical_thermal_abort
    
    slli    t4, t3, 16          # Position into Bits 22:16
    or      t0, t0, t4
    li      t5, 0x800000        # Bit 23
    or      t0, t0, t5          # Enable Threshold #2

    # Write back to Hardware Control CSR
    csrw    0xC04, t0

    # --- 4. SOFTWARE ENVELOPE ALIGNMENT ---
    li      t0, 80
    sw      t0, offset_v_Warning_Threshold(a0)
    li      t0, 90
    sw      t0, offset_v_Panic_Threshold(a0)
    li      t0, 75
    sw      t0, offset_v_Recovery_Target(a0)

    ret

_critical_thermal_abort:
    # Macro replacement: Clear memory and exit
    # In RISC-V Linux, we use 'ecall' to terminate
    # First: zero out the pulse buffer (Stealth Wipe)
    la      t0, pulse_buffer
    li      t1, 64
_wipe_loop:
    sb      zero, 0(t0)
    addi    t0, t0, 1
    addi    t1, t1, -1
    bnez    t1, _wipe_loop

    li      a7, 93              # sys_exit syscall number
    li      a0, 1               # Exit code 1
    ecall

# a0 = ebp equivalent (v_config base)
# t-registers used for logic to avoid pushing/popping every cycle

Check_Hardware_Threshold_Advanced:
    # --- 1. ARCHITECTURAL DISPATCH BARRIER ---
    # RISC-V 'fence' is more granular than mfence/lfence. 
    # i,or = instruction fetch and operand read. w,o = write and output.
    fence   iorw, iorw           # Full system-wide memory barrier

    # --- 2. THERMAL STATUS TELEMETRY PROBE ---
    # Replacing 'rdmsr 19Ch'. In RISC-V, thermal status is often 
    # at a platform-specific CSR (e.g., 0xC03) or MMIO.
    csrr    t0, 0xC03            # Custom CSR: 'mthermal_status'
                                 # t0 = Silicon Status Vector

    # --- 3. MULTI-STAGE THERMAL SIGNATURE ---
    andi    t1, t0, 0x08         # Bit 3: Threshold #2 (90°C)
    bnez    t1, _set_stage_2_flag
    
    andi    t1, t0, 0x02         # Bit 1: Threshold #1 (80°C)
    bnez    t1, _set_stage_1_flag

    # --- 4. HYSTERESIS COHERENCY CHECK ---
    lw      t2, offset_urgent_halt(a0)
    beqz    t2, _exit            # Fast Path: Nominal Flux
    j       _stall_until_cool    # Re-entry to Trap

_set_stage_2_flag:
    # STAGE 2 BREACH: TERMINAL (90°C)
    li      t3, 1
    sw      t3, offset_stage_2_active(a0)
    j       _engage_interlock

_set_stage_1_flag:
    # STAGE 1 BREACH: WARNING (80°C)
    li      t3, 1
    sw      t3, offset_stage_1_active(a0)

_engage_interlock:
    # --- 7. HARDWARE LATCH ACKNOWLEDGMENT ---
    # Clear Bit 1 and 3 in the thermal CSR (wrmsr equivalent)
    li      t4, 0xFFFFFFF5
    and     t0, t0, t4
    csrw    0xC03, t0            # Update CSR to clear sticky bits

    li      t3, 1
    sw      t3, offset_urgent_halt(a0)
    
    # Save a0 (ebp) before sub-call
    addi    sp, sp, -16
    sd      a0, 8(sp)
    sd      ra, 0(sp)
    call    Internal_Synaptic_Pulse
    ld      ra, 0(sp)
    ld      a0, 8(sp)
    addi    sp, sp, 16

_stall_until_cool:
    # --- 8. TEMPORAL TRAP: STALL-GATE ---
    # RISC-V 'pause' hint (part of Zihintpause extension)
    pause                        
    fence   r, r                 # lfence equivalent (read-to-read barrier)

    # --- 9. GUARDIAN HEARTBEAT ENTROPY ---
    lw      t1, offset_guardian_heartbeat(a0)
    lw      t2, offset_last_seen_heartbeat(a0)
    beq     t1, t2, _exit        # Static Heartbeat = Attack/Freeze
    sw      t1, offset_last_seen_heartbeat(a0)

    # --- 10. RECOVERY SYNC ---
    lw      t3, offset_urgent_halt(a0)
    li      t4, 1
    beq     t3, t4, _stall_until_cool

    # --- 11. STATE FINALIZATION ---
    sw      zero, offset_stage_1_active(a0)
    sw      zero, offset_stage_2_active(a0)

    # Final Pulse
    addi    sp, sp, -16
    sd      a0, 8(sp)
    sd      ra, 0(sp)
    call    Internal_Synaptic_Pulse
    ld      ra, 0(sp)
    ld      a0, 8(sp)
    addi    sp, sp, 16

_exit:
    fence   r, r                 # Final Architectural Fence
    ret

#------------------------------------------------------------------------------
# Internal Synaptic Pulse
#------------------------------------------------------------------------------
Internal_Synaptic_Pulse:
    # Stack Prologue
    addi    sp, sp, -32
    sd      ra, 24(sp)
    sd      s0, 16(sp)           # s0 acts as eax/ebp handle
    mv      s0, a0

    # Reset pulse pointer
    la      t0, pulse_buffer
    sd      t0, offset_pulse_buffer_ptr(s0)

    # Ingress: Peer Pulse Collection
    call    Pulse_Ingress_ICMP

    # Evolution: Real-time Feedback
    # Note: RISC-V does not have Intel TSX (transactional memory). 
    # This call now relies on standard Atomic (A-extension) operations.
    call    EvolutionaryFeedback

    ld      s0, 16(sp)
    ld      ra, 24(sp)
    addi    sp, sp, 32
    ret
