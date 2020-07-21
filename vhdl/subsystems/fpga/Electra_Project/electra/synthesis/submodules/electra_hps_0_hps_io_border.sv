// (C) 2001-2017 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


module electra_hps_0_hps_io_border(
// memory
  output wire [15 - 1 : 0 ] mem_a
 ,output wire [3 - 1 : 0 ] mem_ba
 ,output wire [1 - 1 : 0 ] mem_ck
 ,output wire [1 - 1 : 0 ] mem_ck_n
 ,output wire [1 - 1 : 0 ] mem_cke
 ,output wire [1 - 1 : 0 ] mem_cs_n
 ,output wire [1 - 1 : 0 ] mem_ras_n
 ,output wire [1 - 1 : 0 ] mem_cas_n
 ,output wire [1 - 1 : 0 ] mem_we_n
 ,output wire [1 - 1 : 0 ] mem_reset_n
 ,inout wire [32 - 1 : 0 ] mem_dq
 ,inout wire [4 - 1 : 0 ] mem_dqs
 ,inout wire [4 - 1 : 0 ] mem_dqs_n
 ,output wire [1 - 1 : 0 ] mem_odt
 ,output wire [4 - 1 : 0 ] mem_dm
 ,input wire [1 - 1 : 0 ] oct_rzqin
// hps_io
 ,inout wire [1 - 1 : 0 ] hps_io_usb1_inst_D0
 ,inout wire [1 - 1 : 0 ] hps_io_usb1_inst_D1
 ,inout wire [1 - 1 : 0 ] hps_io_usb1_inst_D2
 ,inout wire [1 - 1 : 0 ] hps_io_usb1_inst_D3
 ,inout wire [1 - 1 : 0 ] hps_io_usb1_inst_D4
 ,inout wire [1 - 1 : 0 ] hps_io_usb1_inst_D5
 ,inout wire [1 - 1 : 0 ] hps_io_usb1_inst_D6
 ,inout wire [1 - 1 : 0 ] hps_io_usb1_inst_D7
 ,input wire [1 - 1 : 0 ] hps_io_usb1_inst_CLK
 ,output wire [1 - 1 : 0 ] hps_io_usb1_inst_STP
 ,input wire [1 - 1 : 0 ] hps_io_usb1_inst_DIR
 ,input wire [1 - 1 : 0 ] hps_io_usb1_inst_NXT
 ,output wire [1 - 1 : 0 ] hps_io_spim1_inst_CLK
 ,output wire [1 - 1 : 0 ] hps_io_spim1_inst_MOSI
 ,input wire [1 - 1 : 0 ] hps_io_spim1_inst_MISO
 ,output wire [1 - 1 : 0 ] hps_io_spim1_inst_SS0
 ,inout wire [1 - 1 : 0 ] hps_io_i2c1_inst_SDA
 ,inout wire [1 - 1 : 0 ] hps_io_i2c1_inst_SCL
 ,input wire [1 - 1 : 0 ] hps_io_can1_inst_RX
 ,output wire [1 - 1 : 0 ] hps_io_can1_inst_TX
);

assign hps_io_usb1_inst_D0 = intermediate[1] ? intermediate[0] : 'z;
assign hps_io_usb1_inst_D1 = intermediate[3] ? intermediate[2] : 'z;
assign hps_io_usb1_inst_D2 = intermediate[5] ? intermediate[4] : 'z;
assign hps_io_usb1_inst_D3 = intermediate[7] ? intermediate[6] : 'z;
assign hps_io_usb1_inst_D4 = intermediate[9] ? intermediate[8] : 'z;
assign hps_io_usb1_inst_D5 = intermediate[11] ? intermediate[10] : 'z;
assign hps_io_usb1_inst_D6 = intermediate[13] ? intermediate[12] : 'z;
assign hps_io_usb1_inst_D7 = intermediate[15] ? intermediate[14] : 'z;
assign hps_io_spim1_inst_MOSI = intermediate[17] ? intermediate[16] : 'z;
assign hps_io_i2c1_inst_SDA = intermediate[18] ? '0 : 'z;
assign hps_io_i2c1_inst_SCL = intermediate[19] ? '0 : 'z;

wire [20 - 1 : 0] intermediate;

cyclonev_hps_peripheral_usb usb1_inst(
 .USB_ULPI_STP({
    hps_io_usb1_inst_STP[0:0] // 0:0
  })
,.USB_ULPI_DATA_I({
    hps_io_usb1_inst_D7[0:0] // 7:7
   ,hps_io_usb1_inst_D6[0:0] // 6:6
   ,hps_io_usb1_inst_D5[0:0] // 5:5
   ,hps_io_usb1_inst_D4[0:0] // 4:4
   ,hps_io_usb1_inst_D3[0:0] // 3:3
   ,hps_io_usb1_inst_D2[0:0] // 2:2
   ,hps_io_usb1_inst_D1[0:0] // 1:1
   ,hps_io_usb1_inst_D0[0:0] // 0:0
  })
,.USB_ULPI_NXT({
    hps_io_usb1_inst_NXT[0:0] // 0:0
  })
,.USB_ULPI_DIR({
    hps_io_usb1_inst_DIR[0:0] // 0:0
  })
,.USB_ULPI_DATA_O({
    intermediate[14:14] // 7:7
   ,intermediate[12:12] // 6:6
   ,intermediate[10:10] // 5:5
   ,intermediate[8:8] // 4:4
   ,intermediate[6:6] // 3:3
   ,intermediate[4:4] // 2:2
   ,intermediate[2:2] // 1:1
   ,intermediate[0:0] // 0:0
  })
,.USB_ULPI_CLK({
    hps_io_usb1_inst_CLK[0:0] // 0:0
  })
,.USB_ULPI_DATA_OE({
    intermediate[15:15] // 7:7
   ,intermediate[13:13] // 6:6
   ,intermediate[11:11] // 5:5
   ,intermediate[9:9] // 4:4
   ,intermediate[7:7] // 3:3
   ,intermediate[5:5] // 2:2
   ,intermediate[3:3] // 1:1
   ,intermediate[1:1] // 0:0
  })
);


cyclonev_hps_peripheral_spi_master spim1_inst(
 .SPI_MASTER_RXD({
    hps_io_spim1_inst_MISO[0:0] // 0:0
  })
,.SPI_MASTER_TXD({
    intermediate[16:16] // 0:0
  })
,.SPI_MASTER_SSI_OE_N({
    intermediate[17:17] // 0:0
  })
,.SPI_MASTER_SCLK({
    hps_io_spim1_inst_CLK[0:0] // 0:0
  })
,.SPI_MASTER_SS_0_N({
    hps_io_spim1_inst_SS0[0:0] // 0:0
  })
);


cyclonev_hps_peripheral_i2c i2c1_inst(
 .I2C_DATA({
    hps_io_i2c1_inst_SDA[0:0] // 0:0
  })
,.I2C_CLK({
    hps_io_i2c1_inst_SCL[0:0] // 0:0
  })
,.I2C_DATA_OE({
    intermediate[18:18] // 0:0
  })
,.I2C_CLK_OE({
    intermediate[19:19] // 0:0
  })
);


cyclonev_hps_peripheral_can can1_inst(
 .CAN_TXD({
    hps_io_can1_inst_TX[0:0] // 0:0
  })
,.CAN_RXD({
    hps_io_can1_inst_RX[0:0] // 0:0
  })
);


hps_sdram hps_sdram_inst(
 .mem_dq({
    mem_dq[31:0] // 31:0
  })
,.mem_odt({
    mem_odt[0:0] // 0:0
  })
,.mem_ras_n({
    mem_ras_n[0:0] // 0:0
  })
,.mem_dqs_n({
    mem_dqs_n[3:0] // 3:0
  })
,.mem_dqs({
    mem_dqs[3:0] // 3:0
  })
,.mem_dm({
    mem_dm[3:0] // 3:0
  })
,.mem_we_n({
    mem_we_n[0:0] // 0:0
  })
,.mem_cas_n({
    mem_cas_n[0:0] // 0:0
  })
,.mem_ba({
    mem_ba[2:0] // 2:0
  })
,.mem_a({
    mem_a[14:0] // 14:0
  })
,.mem_cs_n({
    mem_cs_n[0:0] // 0:0
  })
,.mem_ck({
    mem_ck[0:0] // 0:0
  })
,.mem_cke({
    mem_cke[0:0] // 0:0
  })
,.oct_rzqin({
    oct_rzqin[0:0] // 0:0
  })
,.mem_reset_n({
    mem_reset_n[0:0] // 0:0
  })
,.mem_ck_n({
    mem_ck_n[0:0] // 0:0
  })
);

endmodule

