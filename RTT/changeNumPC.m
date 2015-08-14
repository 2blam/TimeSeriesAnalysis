function [last_change_at, numPC] =  changeNumPC (delta, last_change_at, currentTick, holdOffTime, numPC, ndim, ratio)
    updateIt = true;
    
    if(delta < 0)
        %remove number of PC
        if (last_change_at < (currentTick - holdOffTime) & numPC < ndim & delta & numPC > 1)
            updateIt = true;
        else
            updateIt = false;
        end
    else
        %increase number of PC
        if (last_change_at < (currentTick - holdOffTime) & numPC < ndim & delta)
            updateIt = true;
        else
            updateIt = false;
        end
    end
    
    if updateIt
        disp(sprintf('CurrentTick: %d; Changing m from %d to %d (ratio (%f)', currentTick, numPC, (numPC + delta), ratio));
        last_change_at = currentTick;
        numPC = numPC + delta;
    end
end