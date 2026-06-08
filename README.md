# Neural-Network-in-RISC-V

This is just a PoC Neural Network programmed in risc-v. This is for educational purpose only!


This is purely a on-device neural network. This is a direct copy from my MASM neural network version! 
The neural network will have its own themral engine that controls its own thermal input/output, controls 
how it over comes difficult task, re-compiles/re-programs itself without any human input; i.e., the neural net
will look at its opcode table and will choose how to be more stealthy and/or normal to bypass security measures. 

Also uses ADAM, the same optimization algorithm that ChatGPT, and other major AI companies uses to train their 
models, but it's completely re-written in RISC-V. This neural net also uses time dilation couplings for its learning
rate. 

It also has its own internal watch-dog & global cooldown mode for the internal statis mode, see below:


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
