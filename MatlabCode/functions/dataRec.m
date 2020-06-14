    function [rx_data_corrected] = dataRec(rx_filtered, train_idx,cp_size_td,conf)

        begin_training = train_idx + cp_size_td;
        end_training = train_idx + (conf.num_sc + conf.num_cp) * conf.os_factor_OFDM-1;
        
        rx_training= rx_filtered(begin_training : end_training);
        rx_training_fft = osfft(rx_training,conf.os_factor_OFDM);
        
        n = length(rx_training_fft);
        CFR = rx_training_fft ./ conf.training;
        f = (-n/2:n/2-1)*(1.5*conf.BW_bb/n);
         
        figure;
        plot(f,abs(CFR),'LineWidth',3);
        title('Magnitude of channel frequency response');
        xlabel('Frequency (Hz)')
        ylabel('Magnitude')
        grid on
        name=[pwd '/figs/magCFR'];  saveas(gcf,name,'png');
        
        figure;
        plot(f,angle(CFR),'LineWidth',3);
        title('Phase of channel frequency response');
        xlabel('Frequency (Hz)')
        ylabel('Phase (rad) ')
        grid on
        name=[pwd '/figs/phCFR'];  saveas(gcf,name,'png');
        
        CIR = ifft(( CFR));
        pwr = ((abs(CIR)).^2)/((sum(abs(CIR))).^2);
        pwr=circshift(pwr,length(pwr)/2);
        
        [peaks, pos_peaks] = findpeaks(pwr,'MinPeakHeight',0.05*(max(pwr)));
        
        figure;
        t = (0:1/conf.f_s:(length(CIR)-1)/conf.f_s).';
        plot(t, 20*log(circshift(abs(CIR),length(CIR)/2)),'LineWidth',3);
        xlabel('Time (seconds)')
        ylabel('Magnitude (dB)')
        title('Magnitude of channel impulse response');
        grid on
        name=[pwd '/figs/magCIR'];  saveas(gcf,name,'png');
        
        figure;
        stem( (pos_peaks-min(pos_peaks))/conf.f_s ,peaks,'LineWidth',3);
        title('Power Delay Profile');
        xlabel('Time in seconds')
        name=[pwd '/figs/PDP'];  saveas(gcf,name,'png');
       
        data_idx = end_training;
        
        for i = 1:conf.OFDM_symbols
            begin_data = data_idx + cp_size_td;
            end_data = begin_data + conf.num_sc*conf.os_factor_OFDM - 1;
            rx_data = rx_filtered (begin_data : end_data );
            rx_fft = osfft(rx_data,conf.os_factor_OFDM);
            rx_data_corrected(:,i) = rx_fft ./ CFR;
            data_idx = end_data + 1 ;
        end
      
        %       plot((pos_peaks-1)/conf.f_s ,20*log(peaks),'o')
        
end

