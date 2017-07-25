#include <defs.h>
#include <stdio.h>
#include <string.h>
#include <console.h>
#include <kdebug.h>
#include <picirq.h>
#include <trap.h>
#include <clock.h>
#include <intr.h>
#include <pmm.h>
#include <vmm.h>
#include <proc.h>
#include <thumips_tlb.h>
#include <sched.h>

void setup_exception_vector()
{
  //for QEMU sim
  extern unsigned char __exception_vector, __exception_vector_end;
  memcpy((unsigned int*)0xBFC00000, &__exception_vector,
      &__exception_vector_end - &__exception_vector);
}

void __noreturn
kern_init(void) {
    tlb_invalidate_all();

    cons_init();                // init the console

    check_initrd();

    const char *message = "(THU.CST) os is loading ...";
    kprintf("%s\n\n",message);

    print_kerninfo();
    pmm_init();                 // init physical memory management

    pic_init();                 // init interrupt controller
    vmm_init();                 // init virtual memory management
    sched_init();
    proc_init();                // init process table

    ide_init();
    fs_init();

    clock_init();               // init clock interrupt
    intr_enable();              // enable irq interrupt
    cpu_idle();
}

