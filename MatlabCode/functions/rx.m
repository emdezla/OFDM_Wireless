function [rxbits conf] = rx(rxsignal,conf,k)
% Digital Receiver
%
%   [txsignal conf] = tx(txbits,conf,k) implements a complete causal
%   receiver in digital domain.
%
%   rxsignal    : received signal
%   conf        : configuration structure
%   k           : frame index
%
%   Outputs
%
%   rxbits      : received bits
%   conf        : configuration structure
%

    time = (0:1/conf.f_s:(length(rxsignal)-1)/conf.f_s).';
    a = exp(-1j*2*pi*(conf.f_c+conf.offset)*time);
    rx_baseband = rxsignal.*a;

    rx_filtered = 2*ofdmlowpass(rx_baseband,conf, 1.5*conf.BW_bb); %cut off freq = 2*bandwitdth
 
    cp_size_td = conf.num_cp*conf.os_factor_OFDM;
    start_idx = frame_sync(rx_filtered, conf.os_factor ,conf); %
    
    if conf.pilot_mode
            rx_data_corrected = dataRecPilots(rx_filtered, start_idx ,cp_size_td ,conf);  
    else
      rx_data_corrected = dataRec(rx_filtered, start_idx ,cp_size_td ,conf);  
    end
    
    rxbits = demapper(rx_data_corrected,conf);
end

