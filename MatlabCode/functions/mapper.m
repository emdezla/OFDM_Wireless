function [signalQPSK] = mapper(signalBits1D)
signalBits=zeros(2,length(signalBits1D)/2);
signalBits(1,:)=signalBits1D(1:2:end);
signalBits(2,:)=signalBits1D(2:2:end);

signalIndex=bi2de(signalBits.','left-msb');

map=(1/sqrt(2))*[-1-1j, -1+1j, 1-1j, 1+1j];
signalQPSK=map(signalIndex+1);
end

