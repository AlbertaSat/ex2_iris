/*
 *Copyright 2020 University of Alberta
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
*/

/**
 * @file can.h
 * @author Scott Chu
 * @date 2020-08-07
 */

#ifndef CAN_H
#define CAN_H

/* Defining CAN controller registers */
#define CAN0 *((uint32_t *) 0xFFC00000) // CAN controller base address 0
#define CAN1 *((uint32_t *) 0xFFC01000) // CAN controller base address 1
#define CCTRL0 *((uint32_t *) 0xFFC00000) // CAN control register 0
#define CCTRL1 *((uint32_t *) 0xFFC01000) // CAN control register 1
#define CBT0 *((uint32_t *) 0xFFC00000 + 0xC) // Bit timing register 0
#define CBT1 *((uint32_t *) 0xFFC01000 + 0xC) // Bit timing register 1
#define CFR0 *((uint32_t *) 0xFFC00000 + 0x18) // Function register 0
#define CFR1 *((uint32_t *) 0xFFC01000 + 0x18) // Function register 1

/* defining CAN interface registers for CAN controller 0 */
#define IF1CMR *((uint32_t *) 0xFFC00000 + 0x100)
#define IF1MSK *((uint32_t *) 0xFFC00000 + 0x104)
#define IF1ARB *((uint32_t *) 0xFFC00000 + 0x108)
#define IF1MCTR *((uint32_t *) 0xFFC00000 + 0x10C)
#define IF1DA *((uint32_t *) 0xFFC00000 + 0x110)
#define IF1DB *((uint32_t *) 0xFFC00000 + 0x114)

#define IF2CMR *((uint32_t *) 0xFFC00000 + 0x120)
#define IF2MSK *((uint32_t *) 0xFFC00000 + 0x124)
#define IF2ARB *((uint32_t *) 0xFFC00000 + 0x128)
#define IF2MCTR *((uint32_t *) 0xFFC00000 + 0x12C)
#define IF2DA *((uint32_t *) 0xFFC00000 + 0x130)
#define IF2DB *((uint32_t *) 0xFFC00000 + 0x134)

void config_CAN_message(void);

void config_CAN_controller(uint8_t can_controller);

void CAN_RAM_Init(uint8_t can_ram);

int can_init(void);

#endif
