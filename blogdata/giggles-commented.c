#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
/*#include "common.h"*/
#include <stdint.h>

#define NUM_REGISTERS 10
#define TYPE_ADDFUNC 0
#define TYPE_VERIFY 1
#define TYPE_RUNFUNC 2

#define OP_ADD 0
#define OP_BR 1
#define OP_BEQ 2
#define OP_BGT 3
#define OP_MOV 4
#define OP_OUT 5
#define OP_EXIT 6

#define MAX_FUNCS 64
#define MAX_OPS 30
#define MAX_ARGS 10

//#define DBGPRINT(format, ...) fprintf (stderr, format, ## __VA_ARGS__)
#define DBGPRINT(format, ...) do {} while(0);

char *USER = "jit";
int LPORT = 1423;

struct __attribute__ ((__packed__)) operation
{
    uint16_t opcode;
    uint64_t operand1;
    uint64_t operand2;
    uint64_t operand3;
};

/* I can mix up this type with the operation type */
struct __attribute__ ((__packed__)) function
{
    uint16_t num_ops;
    uint16_t num_args;
    uint8_t verified;
    struct operation bytecode[MAX_OPS];
};

struct __attribute__ ((__packed__)) run_func
{
    uint16_t index;
    uint16_t num_args;
    uint32_t args[];
};

uint32_t num_funcs = 0;
struct function funcs[MAX_FUNCS];

int verifyBytecode(struct operation * bytecode, unsigned int n_ops)
{
    unsigned int i;
    for (i = 0; i < n_ops; i++)
    {
        switch (bytecode[i].opcode)
        {
            case OP_MOV:
            case OP_ADD:
                if (bytecode[i].operand1 > NUM_REGISTERS) /* XXX: off-by-one all over the place */
                    return 0;
                else if (bytecode[i].operand2 > NUM_REGISTERS)
                    return 0;
                break;
            case OP_OUT:
                if (bytecode[i].operand1 > NUM_REGISTERS)
                    return 0;
                break;
            case OP_BR:
                if (bytecode[i].operand1 > n_ops)
                    return 0;
                break;
            case OP_BEQ:
            case OP_BGT:
                if (bytecode[i].operand2 > NUM_REGISTERS)
                    return 0;
                else if (bytecode[i].operand3 > NUM_REGISTERS)
                    return 0;
                else if (bytecode[i].operand1 > n_ops)
                    return 0;
                break;
            case OP_EXIT:
                break;
            default:
                return 0;
        }
    }
    return 1;
}

char * executeFunction(struct function * f, uint32_t * args, uint32_t num_args)
{
    unsigned int i;
    uint32_t reg_pc = 0; /* Program counter. */
    uint32_t registers[NUM_REGISTERS];
    int instr_count = 0; /* Signed! */
    char buf[10]; /* Signed! */
    char * result = (char*) calloc(1, 1024); /* Signed! */

    /* Initialize registers to 0 */
    memset(registers, 0, sizeof(registers));

    /* Pre-set the registers to the arguments if there aren't too many. */
    if (num_args < NUM_REGISTERS)
    {
        for (i = 0; i < num_args; i++)
            registers[i] = args[i];
    }

    int done = 0;
    while (!done)
    {
        /* Only execute up to 100 instructions. */
        instr_count++;
        if (instr_count > 100)
            break;

        struct operation * curr_op = &f->bytecode[reg_pc];
        switch (curr_op->opcode)
        {
            case OP_ADD:
                registers[curr_op->operand1] += registers[curr_op->operand2];
                reg_pc++;
                break;
            case OP_BR:
                reg_pc = curr_op->operand1;
                break;
            case OP_MOV:
                registers[curr_op->operand1] = registers[curr_op->operand2];
                reg_pc++;
                break;
            case OP_BEQ:
                if (registers[curr_op->operand2] == registers[curr_op->operand3])
                    reg_pc = curr_op->operand1;
                else
                    reg_pc++;
                break;
            case OP_BGT:
                if (registers[curr_op->operand2] > registers[curr_op->operand3])
                    reg_pc = curr_op->operand1;
                else
                    reg_pc++;
                break;
            case OP_OUT:
                snprintf(buf, 10, "%x ", registers[curr_op->operand1]);
                strcat(result, buf); /* XXX: Buffer overflow here, if we can run more than 113 output instructions, which we can't */
                reg_pc++;
                break;
            case OP_EXIT:
                done = 1;
                break;
            default:
                return NULL;
        }
    }
    return result;
}

int readAll(int fd, char *buffer, size_t length);
int sendAll(int fd, char *buffer, size_t length);

void * JIT;     // TODO: add code to JIT functions
int handleConnection(int sockfd)
{
    void * value = 0;

    /* Map 4096 bytes of executable memory */
    JIT = mmap(0, 4096, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);

    while (1)
    {
        uint8_t type;
        uint16_t len;

        /* Read 1 byte into type */
        if (readAll(sockfd, (char*)&type, 1) != 1)
            exit(0);

        /* Read 2 bytes into length */
        if (readAll(sockfd, (char*)&len, 2) != 2)
            exit(0);

        /* Top out at 4096 bytes (it's unsigned) */
        if (len > 4096)
            len = 4096;

        /* If we already have a value, free it (double free?) */
        if (value)
            free(value);

        /* Allocate exactly enough bytes */
        value = malloc(len);
        if (readAll(sockfd, (char*)value, len) != len)
            exit(0);

        uint32_t send_ret;
        /* There are three possible types. */
        switch (type)
        {
            case TYPE_ADDFUNC:
                DBGPRINT("addfunc\n");
                if (len < 5)
                    break;
                struct function * addFunc = value;

                /* Verify the number of operations (proper unsigned compare) */
                if (addFunc->num_ops > MAX_OPS)
                    break;

                /* Verify the length XXX: (this might be vulnerable to an overflow,
                 * if we need to control it) */
                if (addFunc->num_ops * sizeof(struct operation) + (uintptr_t)&addFunc->bytecode != (uintptr_t)addFunc + len)
                    break;

                /* Mark it as not verified */
                addFunc->verified = 0;

                /* Add it to the funcs array - XXX: I don't see any overflow
                 * protection here . */
                memcpy(&funcs[num_funcs++], addFunc, len);

                send_ret = 0;
                len = 4;

                /* Send back the literal two-byte value "4" */
                if (sendAll(sockfd, (char*)&len, 2) != 2)
                    exit(0);

                /* Send the literal 4-byte value "0" */
                if (sendAll(sockfd, (char*)&send_ret, 4) != 4)
                    exit(0);
                continue;

            case TYPE_VERIFY:
                DBGPRINT("verify\n");

                /* Requires a precisely 2-byte value. */
                if (len != sizeof(uint16_t))
                    break;

                /* Choose the index of the function to verify. */
                uint16_t * p_index = value;

                /* Verify it isn't too big. */
                if (*p_index >= num_funcs)
                    break;

                /* Verify the bytecode is sane. */
                if (!verifyBytecode(funcs[*p_index].bytecode, funcs[*p_index].num_ops))
                    break;

                /* Mark it as verified. */
                funcs[*p_index].verified = 1;

                send_ret = 0;
                len = 4;
                if (sendAll(sockfd, (char*)&len, 2) != 2)
                    exit(0);
                if (sendAll(sockfd, (char*)&send_ret, 4) != 4)
                    exit(0);
                continue;
            case TYPE_RUNFUNC:
                DBGPRINT("runfunc\n");
                if (len < sizeof(struct run_func))
                    break;
                struct run_func * runFunc = value;

                /* Check if num_args is more than MAX_ARGS (XXX: off-by-one?) */
                if (runFunc->num_args > MAX_ARGS)
                    break;

                /* Confusing sanity check */
                if (runFunc->num_args * sizeof(uint32_t) + (uintptr_t)&runFunc->args != (uintptr_t)runFunc + len)
                    break;

                /* Make sure the function is valid. */
                if (runFunc->index >= num_funcs)
                    break;

                /* Check if it's verified. */
                if (funcs[runFunc->index].verified == 0)
                    break;

                /* The magic happens here */
                char * output = executeFunction(&funcs[runFunc->index], runFunc->args, runFunc->num_args);

                /* Get the length. */
                len = strlen(output);

                /* Send the length. */
                if (sendAll(sockfd, (char*)&len, 2) != 2)
                    exit(0);

                /* Send the output. */
                if (sendAll(sockfd, output, strlen(output)) != (int)strlen(output))
                    exit(0);

                free(output);
                continue;
        }

        /* This is the error case. */
        send_ret = 0xFFFFFFFF;
        len = 4;
        if (sendAll(sockfd, (char*)&len, 2) != 2)
            exit(0);
        if (sendAll(sockfd, (char*)&send_ret, 4) != 4)
            exit(0);
    }

	return 0;
}

