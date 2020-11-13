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
 * @file init_seq.c
 * @author Scott Chu
 * @date 2020-06-29
 */

#define soc_cv_av

/* Standard library includes. */
#include <stdio.h>
#include <stdint.h>
#include <stddef.h>

/* Altera hardware lib includes*/
#include "hps.h"
#include "socal.h"
#include "hwlib.h"
#include "alt_spi.h"


void config_spi()
{
	unsigned int CTLR0;
	unsigned int BAUDR;
	unsigned int TXFTLR;
	unsigned int IMR;

	CTLR0 = ALT_SPIM_CTLR0_DFS_SET(ALT_SPIM_CTLR0_DFS_E_WIDTH4BIT)|
			ALT_SPIM_CTLR0_FRF_SET(ALT_SPIM_CTLR0_FRF_E_MOTSPI)|
			ALT_SPIM_CTLR0_SCPH_SET(ALT_SPIM_CTLR0_SCPH_E_MIDBIT)|
			ALT_SPIM_CTLR0_SCPOL_SET(ALT_SPIM_CTLR0_SCPOL_E_INACTLOW)|
			ALT_SPIM_CTLR0_TMOD_SET(ALT_SPIM_CTLR0_TMOD_E_TXONLY)|
			ALT_SPIM_CTLR0_SRL_SET(ALT_SPIM_CTLR0_SRL_E_NORMMOD)|
			ALT_SPIM_CTLR0_CFS_SET(0);

//	ALT_SPIM_TXFTLR_TFT_SET(value)
//	ALT_SPIM_RXFTLR_RFT_SET(value)

	alt_write_word(ALT_SPIM0_SPIENR_ADDR, ALT_SPIM_SPIENR_SPI_EN_E_DISD); // Disable SPI master
	alt_write_word(ALT_SPIM0_CTLR0_ADDR, CTLR0); //

}

