close all
clear all
clc

addpath('functions')
% % % % %
% Wireless Receivers: algorithms and architectures
% Audio Transmission Framework 
%
%
%   3 operating modes:
%   - 'matlab' : generic MATLAB audio routines (unreliable under Linux)
%   - 'native' : OS native audio system
%       - ALSA audio tools, most Linux distrubtions
%       - builtin WAV tools on Windows 
%   - 'bypass' : no audio transmission, takes txsignal as received signal

% Configuration Values
conf.audiosystem = 'bypass'; % Values: 'matlab','native','bypass'

conf.OFDM_symbols  = 10;   % number of OFDM symbols

conf.f_s     = 48000;      % sampling rate  
conf.f_c     = 8000;       % carrier frequency
conf.f_spacing = 5;        % spacing frequency

conf.num_sc = 256;         % number of subcarriers in one QFDM symbol
conf.f_sym   = 100;        % symbol rate
conf.sym_duration = conf.num_sc/conf.f_sym; % symbol duration: T = N/R
conf.BW_bb  = ceil((conf.num_sc +1)/2)*conf.f_spacing; %bandwith

conf.modulation_order = 2; % BPSK:1, QPSK:2
conf.bitsps     = 16;      % bits per audio sample
conf.offset     = 0;

conf.pilot_mode = false;
conf.pilotRate = 2;                 % It is not properly a rate, it defines a pilot inserted every n data 
conf.numPilots = (conf.OFDM_symbols - mod(conf.OFDM_symbols,conf.pilotRate))/conf.pilotRate;
    if mod(conf.OFDM_symbols,conf.pilotRate) == 0
        conf.numPilots = conf.numPilots - 1;
    end

conf.os_factor_OFDM = conf.f_s/(conf.f_spacing*conf.num_sc);
conf.os_factor  = conf.f_s/conf.f_sym;
if mod(conf.os_factor,1) ~= 0
   disp('WARNING: Sampling rate must be a multiple of the symbol rate'); 
end

rolloff_factor = 0.22;
conf.tx_filterlen = 10*conf.os_factor;
conf.pulse = rrc(conf.os_factor, rolloff_factor, conf.tx_filterlen);

conf.npreamble  = 100;  % number of symbols in preamble
conf.preamble = -2*(genpreamble(conf.npreamble)-0.5); %generate BPSK preamble
conf.preamble_os = zeros(conf.os_factor*conf.npreamble,1);
conf.preamble_os(1:conf.os_factor:end) = conf.preamble;
conf.preamble_os = conv(conf.preamble_os, conf.pulse.', 'same');

conf.training = -2*(randi([0 1],conf.num_sc,1)-0.5);  %generate BPSK training

conf.nbits   = conf.num_sc * conf.OFDM_symbols * 2;
conf.nsyms  = ceil(conf.nbits/conf.modulation_order);


%test_cp = 0:10:100;
%conf.nframes = length(test_cp);         % number of frames to transmit

conf.nframes = 1;
conf.num_cp = 128; 

% Initialize result structure with zero
res.biterrors   = zeros(conf.nframes,1);
res.rxnbits     = zeros(conf.nframes,1);
%per = zeros(length(test_cp),1);
%ber = zeros(length(test_cp),1);


for k=1:conf.nframes
    
    txbits = randi([0 1],conf.nbits,1);
 
    [txsignal,conf] = tx(txbits,conf,k);
 
    % % % % % % % % % % % %
    % Begin
    % Audio Transmission
    %
    
    % normalize values
    peakvalue       = max(abs(txsignal));
    normtxsignal    = txsignal / (peakvalue + 0.3);
    
    % create vector for transmission
    rawtxsignal = [ zeros(conf.f_s,1) ; normtxsignal ;  zeros(conf.f_s,1) ]; % add padding before and after the signal
    rawtxsignal = [ rawtxsignal  zeros(size(rawtxsignal)) ]; % add second channel: no signal
    txdur       = length(rawtxsignal)/conf.f_s; % calculate length of transmitted signal
    
    % wavwrite(rawtxsignal,conf.f_s,16,'out.wav')   
    audiowrite('out.wav',rawtxsignal,conf.f_s)  
    
    % Platform native audio mode 
    if strcmp(conf.audiosystem,'native')
        
        % Windows WAV mode 
        if ispc()
            disp('Windows WAV');
            wavplay(rawtxsignal,conf.f_s,'async');
            disp('Recording in Progress');
            rawrxsignal = wavrecord((txdur+1)*conf.f_s,conf.f_s);
            disp('Recording complete')
            rxsignal = rawrxsignal(1:end,1);

        % ALSA WAV mode 
        elseif isunix()
            disp('Linux ALSA');
            cmd = sprintf('arecord -c 2 -r %d -f s16_le  -d %d in.wav &',conf.f_s,ceil(txdur)+1);
            system(cmd); 
            disp('Recording in Progress');
            system('aplay  out.wav')
            pause(2);
            disp('Recording complete')
            rawrxsignal = wavread('in.wav');
            rxsignal    = rawrxsignal(1:end,1);
        end
        
    % MATLAB audio mode
    elseif strcmp(conf.audiosystem,'matlab')
        disp('MATLAB generic');
        playobj = audioplayer(rawtxsignal,conf.f_s,conf.bitsps);
        recobj  = audiorecorder(conf.f_s,conf.bitsps,1);
        record(recobj);
        disp('Recording in Progress');
        playblocking(playobj)
        pause(0.5);
        stop(recobj);
        disp('Recording complete')
        rawrxsignal  = getaudiodata(recobj,'int16');
        rxsignal     = double(rawrxsignal(1:end))/double(intmax('int16')) ;
        
    elseif strcmp(conf.audiosystem,'bypass')
        rawrxsignal = rawtxsignal(:,1);
        rxsignal    = rawrxsignal;
    end
    
    % Plot received signal for debgging
    time = (0:1/conf.f_s:(length(rxsignal)-1)/conf.f_s).';
    plot(time,rxsignal);
    title('Received Signal')
    
    %
    % End
    % Audio Transmission   
    % % % % % % % % % % % %
    
    % TODO: Implement rx() Receive Function
    
    [rxbits,conf]       = rx(rxsignal,conf);
    
    res.rxnbits(k)      = length(rxbits);  
    res.biterrors(k)    = sum(rxbits ~= txbits);
    
     per(k) = sum(res.biterrors > 0)/conf.nframes;
     ber(k) = sum(res.biterrors)/sum(res.rxnbits)
    
    
end

%figure;

%plot(test_cp, ber, '-');

%xlabel('Cyclic Prefix Length')
%ylabel('Bit Error Rate')
%title('BER vs CP length')

