#include <stm32f4xx_conf.h>


void GPIO_Config() {
    GPIO_InitTypeDef	GPIO_InitStructure;

    RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOA, ENABLE);
      //    GPIO_PinRemapConfig(GPIO_Remap_SWJ_JTAGDisable, ENABLE); /* free PB.3 & PB.4 */

    /* init GPIO output in bank.A */
    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_15;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_OUT;
    GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
    GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL;
    GPIO_Init(GPIOA, &GPIO_InitStructure);
}

void delay(){
  int i,j;
  for (i=0; i<999; i++)
    for (j=0; j<9999; j++)
      ;
}

int main (void)
{
  SystemInit();
  GPIO_Config();
  while(1){
    delay();
    GPIO_SetBits(GPIOA, GPIO_Pin_15);
    delay();
    GPIO_ResetBits(GPIOA, GPIO_Pin_15);    
    
  }
}
