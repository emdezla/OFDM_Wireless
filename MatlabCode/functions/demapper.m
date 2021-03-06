function b = demapper(a,conf)
% Convert noisy QPSK symbols into a bit vector. Hard decisions.

if (conf.modulation_order == 1)
    b = (real(a)<0);
    
else 
    a = a(:); % Make sure "a" is a column vector

    b = [real(a) imag(a)] > 0;

    % Convert the matrix "b" to a vector, reading the elements of "b" rowwise.
    b = b.';
    b = b(:);

    b = double(b); % Convert data type from logical to double
end
end