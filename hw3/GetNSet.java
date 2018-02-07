import java.util.concurrent.atomic.AtomicIntegerArray;

class GetNSet implements State {
    private AtomicIntegerArray value;
    private byte maxval;

    private int[] convertByteArrToIntArr(byte[] v) {
        int[] res = new int[v.length];
        for (int i = 0; i < v.length; i++){
            res[i] = v[i];
        }
        return res;
    }

    private byte[] convertAtomicIntArrToByteArr(AtomicIntegerArray v) {
        byte[] res = new byte[v.length()];
        for (int i = 0; i < v.length(); i++) {
            res[i] = (byte) v.get(i); // need to cast because downcasting, make sure each element not stored in too large blocks
        }
        return res;
    }

    GetNSet(byte[] v) {
        int[] intArray = convertByteArrToIntArr(v);
        this.value = new AtomicIntegerArray(intArray);
        this.maxval = 127;
    }

    GetNSet(byte[] v, byte maxval) {
        int[] intArray = convertByteArrToIntArr(v);
        this.value = new AtomicIntegerArray(intArray);
        this.maxval = maxval;
    }

    public int size() { return value.length(); }

    public byte[] current() {
        return convertAtomicIntArrToByteArr(this.value);
    }

    public synchronized boolean swap(int i, int j) {
        int old_i = value.get(i);
        int old_j = value.get(j);
        if (old_i <= 0 || old_j >= maxval) {
            return false;
        }
        value.set(i, old_i - 1);
        value.set(j, old_j + 1);
        return true;
    }
}