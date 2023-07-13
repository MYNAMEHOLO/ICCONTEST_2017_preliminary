# ICCONTEST_2017_pre
## 本題評分標準及結果
### 最終結果為CLASS A
### 本題評分標準為 Area < 12500 並且 simulation time小於1,920,000ns 為 Class A
### 本作 Cell Area：11645
### Simulation Time: 3,052,330ns
### 本題不能更改sdc但可以更改其中的Cycle,可參考作者提供的Area,Timing log.
## DT(距離變換)
本題描述的演算法是關於圖像前景及背景的距離變換的演算法，由於這一題使用到R/W single port的RAM，且正負緣判斷較先前寫過的題目有些許不同，導致我本人在時序處理上面多花了一些時間，最後也為了debugging方便把狀態機的數量增加到20餘個不過仍然有一些可化簡的空間。

詳細的核心思路為
首先考慮到必須到本題會對一張圖像進行處理，並且需要隨時更新，這樣的特性讓我第一步先選擇把ROM當中的資料取出並且存到RAM裡面，之後再按照題目的演算法來實作前景及背景。

值得注意的地方是，跟實驗室同學討論時發現TestBench其實有暗藏玄機。

```veilog=!
initial begin // FW-PASS result compare
fwpass_chk = 0;
	#(`CYCLE*3);
	wait( fwpass_finish ) ;
	fwpass_chk = 1;
	fw_err = 0;
	for (i=0; i <N_PAT ; i=i+1) begin
				exp_pat = exp_fwpass[i];
				rel_pat = u_res_RAM.res_M[i];
				if (exp_pat == rel_pat) begin
					fw_err = fw_err;
				end
				else begin 
					fw_err = fw_err+1;
					if (fw_err <= 30) $display("FWPASS : Output pixel %d are wrong! the real output is %h, but expected result is %h", i, rel_pat, exp_pat);
					if (fw_err == 31) begin $display("FWPASS : Find the wrong pixel reached a total of more than 30 !, Please check the code .....\n");  end
				end
				if( ((i%1000) === 0) || (i == 16383))begin  
					if ( fw_err === 0)
      					$display("FWPASS : Output pixel: 0 ~ %d are correct!\n", i);
					else
					$display("FWPASS : Output Pixel: 0 ~ %d are wrong ! The wrong pixel reached a total of %d or more ! \n", i, fw_err);
					
  				end					
	end
end 
```
從Testfixture.v當中的這一段被註解起來的程式發現，我們似乎不用那麼辛苦地去追從頭到尾的記憶體數值，而是在前景做完時就能夠透過拉起Testfixture.v當中的fwpass_finish訊號來進行數值的確認，可以大幅度的降低開發及Debugging的時間。

至於一開始ROM的讀取部分，我個人使用Verdi的 MDA dump/analyzer功能來觀察數值有沒有被正確的讀入，並在一開始的時候發現記憶體資料的讀取也算是有些耐人尋味，就在一開始的讀取步驟就先將高低位元進行調換，如此才能得到正確的數值。
