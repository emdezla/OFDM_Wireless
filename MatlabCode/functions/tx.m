function [txsignal conf] = tx(txbits,conf,k)
% Digital Transmitter
%
%   [txsignal conf] = tx(txbits,conf,k) implements a complete transmitter
%   consisting of:
%       - modulator
%       - pulse shaping filter
%       - up converter
%   in digital domain.
%
%   txbits  : Information bits
%   conf    : Universal configuration structure
%   k       : Frame index
%

txbits_bpsk = 2*(txbits-0.5);
txbits_qpsk = 1/sqrt(2)*(txbits_bpsk(1:2:end) + 1i*txbits_bpsk(2:2:end)); 
txbits_total = vertcat(conf.training,txbits_qpsk);

tx_parallel = reshape(txbits_total,[conf.num_sc,length(txbits_total)/conf.num_sc]);

if conf.pilot_mode
   pilotPos = 1:conf.pilotRate+1:(size(tx_parallel,2)+conf.numPilots);
   kk_parallel=zeros(256,size(tx_parallel,2)+conf.numPilots);
   kk_parallel(:,pilotPos)=repmat(conf.training,1,conf.numPilots+1);
   dataPos = find(all(kk_parallel==0));
   kk_parallel(:,dataPos)=tx_parallel(:,2:end);
   tx_parallel = kk_parallel;
end

sizetx = size(tx_parallel);

for i = 1:sizetx(2)
    tx_ifft(:,i) = osifft(tx_parallel(:,i),conf.os_factor_OFDM);
end

cp = tx_ifft(end-conf.num_cp*conf.os_factor_OFDM +1:end,:);     % cyclic prefix extraction
tx_cp = vertcat (cp,tx_ifft);                                   % cyclic prefix addition
signal = vertcat(conf.preamble_os/max(conf.preamble_os), tx_cp(:)/max(tx_cp(:)) );

time = (0:1/conf.f_s:(length(signal)-1)/conf.f_s).';
txsignal = real(signal.*exp(1j*2*pi*conf.f_c*time));

%figure
%plot(time,txsignal);


end
