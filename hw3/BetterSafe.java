import java.util.concurrent.locks.ReentrantLock;

class BetterSafe implements State {
    private byte[] value;
    private byte maxval;
    private ReentrantLock lock;

    BetterSafe(byte[] v) { 
        value = v; 
        maxval = 127; 
        lock = new ReentrantLock();
    }

    BetterSafe(byte[] v, byte m) { 
        value = v; 
        maxval = m; 
        lock = new ReentrantLock();
    }

    public int size() { return value.length; }

    public byte[] current() { return value; }

    // reentrant locks will make function faster than synchronized function by locking only critical sections
    public boolean swap(int i, int j) {
        lock.lock();
        if (value[i] <= 0 || value[j] >= maxval) {
            lock.unlock();
            return false;
        }
        value[i]--;
        value[j]++;
        lock.unlock();
        return true;
    }
}