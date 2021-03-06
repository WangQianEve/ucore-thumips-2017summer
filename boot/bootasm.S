/* 
  Bootloader for MIPS32S
  Refering from Chen Yuheng, Rewritten by Wang Qian
  2012/07/16 | 2017/07/11
 */

#define FLASH_START 0xBE000000
#define FLASH_SIZE  0x01000000
#define ELF_MAGIC 0x464C457F

/* load a 32bit word from Flash, 
 * off is byte-addressed */
/* off = offset from s0 
 * t7 to 4bit 
 * t7 += s0 :real addr 
 * dst = mem[t7] 
 * t7 = mem[t7+4] 
 * t7 = t7<<16 
 * dst = whole 32 bit */
#define LOAD_WORD_I(dst, off) \
  li $t7, off; \
  sll $t7, $t7, 1; \
  addu $t7, $s0, $t7; \
  lw dst, 0($t7); \
  lw $t7, 4($t7); \
  sll $t7, $t7, 16; \
  or dst, dst, $t7

#define LOAD_WORD_R(dst, off, base) \
  addiu $t7, base, off;\
  sll  $t7, $t7, 1; \
  addu $t7, $s0, $t7; \
  lw dst, 0($t7); \
  lw $t7, 4($t7); \
  sll $t7, $t7, 16; \
  or dst, dst, $t7;
   
.set noreorder
.set noat
.globl __start
__start:

load_elf:
  #dirty hack : store 00ff to flash end?
  la $t0, (FLASH_START+FLASH_SIZE - 8)
  la $t1, 0x00FF
  sw $t1, 0($t0)

  #addr of elfheader, s0
  #t1: flash first value
  la $s0, FLASH_START
  LOAD_WORD_I($t1, 0)
  #t0:e_magic
  la $t0, ELF_MAGIC
  beq $t0, $t1, load_ini
  nop
  b bad
  nop

load_ini:
  #e_phoff
  LOAD_WORD_I($s1, 28)
  #e_phnum
  LOAD_WORD_I($s2, 44)
  andi $s2, $s2, 0xFFFF
  #e_entry
  LOAD_WORD_I($s3, 24)

gain_sec:
  #s1, addr proghdr
  #s4, p_va
  LOAD_WORD_R($s4, 8, $s1)
  #s5, p_filesz
  LOAD_WORD_R($s5, 16, $s1)
  #s6, p_offset
  LOAD_WORD_R($s6, 4, $s1)

  beq  $s4, $zero, next_sec
  nop
  beq  $s5, $zero, next_sec
  nop

copy_sec:
  LOAD_WORD_R($t0, 0, $s6)
  sw $t0, 0($s4)
  addiu $s6, $s6, 4
  addiu $s4, $s4, 4
  addiu $s5, $s5, -4
  bgtz  $s5, copy_sec
  nop

next_sec:
  addiu $s1, $s1, 32
  addiu $s2, $s2, -1
  bgtz  $s2, gain_sec
  nop

done:
#jump to kernel
  jr $s3
  nop

bad:
#give some output?
  b bad 
  nop

