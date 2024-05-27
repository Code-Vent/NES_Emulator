#pragma once
#include<stdint.h>
#include<assert.h>
#include<iostream>

typedef uint8_t byte;

template<typename T>
class MemoryIterator;
template<typename T>
class MemoryReverseIterator;

template<typename T>
struct Memory {
	friend class MemoryIterator<T>;
	using MI = MemoryIterator<T>;
public:
	Memory() = default;
	void* operator new(size_t size, void* ptr);
	MemoryIterator<T> begin();
	MemoryIterator<T> end();
	MemoryReverseIterator<T> rbegin();
	MemoryReverseIterator<T> rend();
	static void swap(MemoryIterator<T>& a, MemoryIterator<T>& b);
	void load(T value);
	T read();
	void set_bit(uint8_t bit);
	void clear_bit(uint8_t bit);
	void ANDed(T mask);
	void ORed(T mask);
	void XORed(T mask);
	void mirror();
	void LSH(uint8_t);
	void RSH(uint8_t);
	void ROR(uint8_t);
	void ROL(uint8_t);
	int at(int i);
	Memory<uint8_t>* get_byte_at(uint8_t);
	void	put_byte_at(uint8_t, uint8_t);


	void operator+=(const Memory<T>&);
	void operator-=(const Memory<T>&);
	
private:
	volatile T value;
	static constexpr int Nbits = 8 * sizeof(T);
};

template<typename T>
class MemoryIterator {
public:
	MemoryIterator() = default;
	MemoryIterator(Memory<T>* m, int i = 0);
	bool operator!=(const MemoryIterator& rhs)const;
	bool operator<(const MemoryIterator& rhs)const;
	MemoryIterator& operator++();
	MemoryIterator operator+(int i);
	MemoryIterator& operator=(int i);
	int operator*();
	void reset();
protected:
	int curr_index;
	Memory<T>* memory;
};

template<typename T>
class MemoryReverseIterator : public MemoryIterator<T> {
public:
	MemoryReverseIterator() = default;
	MemoryReverseIterator(Memory<T>* m, int i = 0);
	MemoryReverseIterator& operator++();
	MemoryReverseIterator& operator=(int i) {
		MemoryIterator<T>::operator=(i);
		return *this;
	}
	void reset();
};

template<typename T>
class MemoryMappedDevice;

template<typename T>
class Driver {
	friend class MemoryMappedDevice<T>;
public:	
	virtual bool configure() const { return false; };
	virtual bool available() const { return true; }
	virtual T get() const { return 0xFFFFFFF0; }
	virtual void put(T) const {}
	virtual void update() const {}
protected:
	Driver() {
		registers = nullptr;
	}
	mutable Memory<T>* registers;
};

template<typename T>
class MemoryMapped;

template<typename T>
class MemoryMappedIterator {
public:
	MemoryMappedIterator() = default;
	MemoryMappedIterator(MemoryMapped<T>* mm, int i, int size);
	bool operator!=(const MemoryMappedIterator<T>& rhs);
	MemoryMappedIterator<T>& operator++();
	MemoryMappedIterator<T> operator+(int i);
	void operator+=(int i);
	Memory<T>& operator*();
	Memory<T>* operator->();
	void reset();
protected:
	int curr_index;
	int _size;
	MemoryMapped<T>* mmap;
};

template<typename T>
class MemoryMappedReverseIterator : public MemoryMappedIterator<T> {
public:
	MemoryMappedReverseIterator() = default;
	MemoryMappedReverseIterator(MemoryMapped<T>* mm, int i, int size);
	MemoryMappedReverseIterator& operator++();
	void reset();
};

template<typename T>
class MemoryMapped {
	friend class MemoryMappedIterator<T>;
public:
	MemoryMapped() = default;
	MemoryMapped(void* base, size_t size);
	size_t size() { return _size; }
	MemoryMappedIterator<T> begin();
	const MemoryMappedIterator<T>& end();
	MemoryMappedReverseIterator<T> rbegin();
	const MemoryMappedReverseIterator<T>& rend();
	Memory<T>* at(int i);
protected:
	Memory<T>* _begin();
	Memory<T>* _end();
private:
	Memory<T>* start;
	size_t _size;
};

template<typename T>
class MemoryMappedDevice : public MemoryMapped<T> {
public:
	MemoryMappedDevice() = default;
	MemoryMappedDevice(void* base, size_t size, const Driver<T>*);
	const Driver<T>* get_device();
private:
	const Driver<T>* device;
};

template<typename T>
inline void* Memory<T>::operator new(size_t size, void* ptr)
{
	return ptr;
}

template<typename T>
inline MemoryIterator<T> Memory<T>::begin()
{
	return MemoryIterator<T>(this, 0);
}

template<typename T>
inline MemoryIterator<T> Memory<T>::end()
{
	return MemoryIterator<T>(this, Nbits);
}

template<typename T>
inline MemoryReverseIterator<T> Memory<T>::rbegin()
{
	return MemoryReverseIterator<T>(this, Nbits - 1);
}

template<typename T>
inline MemoryReverseIterator<T> Memory<T>::rend()
{
	return MemoryReverseIterator<T>(this, -1);
}

template<typename T>
inline void Memory<T>::swap(MemoryIterator<T>& a, MemoryIterator<T>& b)
{
	auto temp = *a;
	a = *b;
	b = temp;
}

template<typename T>
inline void Memory<T>::load(T value)
{
	this->value = value;
}

template<typename T>
inline T Memory<T>::read()
{
	return value;
}

template<typename T>
inline void Memory<T>::set_bit(uint8_t bit)
{
	assert(bit < Nbits);
	value |= (1u << bit);
}

template<typename T>
inline void Memory<T>::clear_bit(uint8_t bit)
{
	assert(bit < Nbits);
	value &= ~(1u << bit);
}

template<typename T>
inline void Memory<T>::ANDed(T mask)
{
	value &= mask;
}

template<typename T>
inline void Memory<T>::ORed(T mask)
{
	value |= mask;
}

template<typename T>
inline void Memory<T>::XORed(T mask)
{
	value ^= mask;
}

template<typename T>
inline void Memory<T>::mirror()
{
	auto t1 = this->begin();
	auto t2 = this->rbegin();
	while (t1 < t2) {
		swap(t1, t2);
		++t1; ++t2;
	}
}

template<typename T>
inline void Memory<T>::LSH(uint8_t n)
{
	this->value <<= n;
}

template<typename T>
inline void Memory<T>::RSH(uint8_t n)
{
	this->value >>= n;
}

template<typename T>
inline void Memory<T>::ROR(uint8_t n)
{
	n %= Nbits;
	while (n--) {
		T temp = value & 0x1;
		temp <<= (Nbits - 1);
		RSH(1);
		value |= temp;
	}
}

template<typename T>
inline void Memory<T>::ROL(uint8_t n)
{
	n %= Nbits;
	while (n--) {
		T temp = value & (0x1 << (Nbits - 1));
		temp >>= (Nbits - 1);
		LSH(1);
		value |= temp;
	}
}

template<typename T>
inline int Memory<T>::at(int i)
{
	MemoryIterator<T> it(this, i);
	return *it;
}

template<typename T>
inline void Memory<T>::put_byte_at(uint8_t b, uint8_t n)
{
	assert(n < sizeof(T));
	auto bytes = reinterpret_cast<volatile byte*>(this);
	bytes[n] = b;
}

template<typename T>
inline void Memory<T>::operator+=(const Memory<T>& rhs)
{
	value += rhs.value;
}

template<typename T>
inline void Memory<T>::operator-=(const Memory<T>& rhs)
{
	value -= rhs.value;
}

template<typename T>
inline Memory<uint8_t>* Memory<T>::get_byte_at(uint8_t n)
{
	assert(n < sizeof(T));
	auto bytes = reinterpret_cast<byte*>(this);
	void* address = reinterpret_cast<void*>(bytes + n);
	return new(address)Memory<uint8_t>;
}

template<typename T>
inline MemoryIterator<T>::MemoryIterator(Memory<T>* m, int i)
{
	memory = m;
	curr_index = i;
}

template<typename T>
inline bool MemoryIterator<T>::operator!=(const MemoryIterator& rhs)const
{
	return this->curr_index != rhs.curr_index;
}

template<typename T>
inline bool MemoryIterator<T>::operator<(const MemoryIterator& rhs)const
{
	return this->curr_index < rhs.curr_index;
}

template<typename T>
inline MemoryIterator<T>& MemoryIterator<T>::operator++()
{
	// TODO: insert return statement here
	assert(curr_index < Memory<T>::Nbits);
	++curr_index;
	return *this;
}

template<typename T>
inline MemoryIterator<T> MemoryIterator<T>::operator+(int i)
{
	// TODO: insert return statement here
	return MemoryIterator<T>{this->memory, this->curr_index + i};
}

template<typename T>
inline MemoryIterator<T>& MemoryIterator<T>::operator=(int i)
{
	// TODO: insert return statement here
	if (i) {
		memory->value |= 1u << curr_index;
	}
	else {
		memory->value &= ~(1u << curr_index);
	}
	return *this;
}

template<typename T>
inline int MemoryIterator<T>::operator*()
{
	return (memory->value >> curr_index) & 0x01;
}

template<typename T>
inline void MemoryIterator<T>::reset()
{
	this->curr_index = 0;
}

template<typename T>
inline MemoryMappedIterator<T>::MemoryMappedIterator(MemoryMapped<T>* mm, int i, int size)
{
	assert(i <= size);
	mmap = mm;
	curr_index = i;
	_size = size;
}

template<typename T>
inline bool MemoryMappedIterator<T>::operator!=(const MemoryMappedIterator<T>& rhs)
{
	return this->curr_index != rhs.curr_index;
}

template<typename T>
inline MemoryMappedIterator<T>& MemoryMappedIterator<T>::operator++()
{
	// TODO: insert return statement here
	
	++curr_index;
	return *this;
}

template<typename T>
inline MemoryMappedIterator<T> MemoryMappedIterator<T>::operator+(int i)
{
	// TODO: insert return statement here
	return MemoryMappedIterator<T>{this->mmap, this->curr_index + i, this->_size};
}

template<typename T>
inline void MemoryMappedIterator<T>::operator+=(int i)
{
	assert(curr_index + i < mmap->_size);
	curr_index += i;
}

template<typename T>
inline Memory<T>& MemoryMappedIterator<T>::operator*()
{
	// TODO: insert return statement here
	return *mmap->at(curr_index);
}

template<typename T>
inline Memory<T>* MemoryMappedIterator<T>::operator->()
{
	// TODO: insert return statement here
	return &*mmap->at(curr_index);
}

template<typename T>
inline void MemoryMappedIterator<T>::reset()
{
	this->curr_index = 0;
}

template<typename T>
inline MemoryReverseIterator<T>::MemoryReverseIterator(Memory<T>* m, int i)
	:MemoryIterator<T>(m, i)
{
}

template<typename T>
inline MemoryReverseIterator<T>& MemoryReverseIterator<T>::operator++()
{
	// TODO: insert return statement here
	assert(this->curr_index > -1);
	--this->curr_index;
	return *this;
}

template<typename T>
inline void MemoryReverseIterator<T>::reset()
{
	this->curr_index = Memory<T>::Nbits - 1;
}

template<typename T>
inline MemoryMappedReverseIterator<T>::MemoryMappedReverseIterator(MemoryMapped<T>* mm, int i, int size)
	:MemoryMappedIterator<T>(mm, i, size)
{
}

template<typename T>
inline MemoryMappedReverseIterator<T>& MemoryMappedReverseIterator<T>::operator++()
{
	// TODO: insert return statement here
	assert(this->curr_index > -1);
	--this->curr_index;
	return *this;
}

template<typename T>
inline void MemoryMappedReverseIterator<T>::reset()
{
	this->curr_index = this->_size - 1;
}

template<typename T>
inline MemoryMapped<T>::MemoryMapped(void* base, size_t size)
{
	start = new(base)Memory<T>;
	this->_size = size;
}

template<typename T>
inline MemoryMappedIterator<T> MemoryMapped<T>::begin()
{
	return MemoryMappedIterator<T>(this, 0, _size);
}

template<typename T>
inline const MemoryMappedIterator<T>& MemoryMapped<T>::end()
{
	static const auto End = MemoryMappedIterator<T>(this, _size, _size);
	return End;
}

template<typename T>
inline MemoryMappedReverseIterator<T> MemoryMapped<T>::rbegin()
{
	return MemoryMappedReverseIterator<T>(this, _size - 1, _size);
}

template<typename T>
inline const MemoryMappedReverseIterator<T>& MemoryMapped<T>::rend()
{
	const auto rEnd = MemoryMappedReverseIterator<T>(this, -1, _size);
	return rEnd;
}

template<typename T>
inline Memory<T>* MemoryMapped<T>::at(int i)
{
	assert(i < (int)_size);
	return start + i;
}

template<typename T>
inline Memory<T>* MemoryMapped<T>::_begin()
{
	return start;
}

template<typename T>
inline Memory<T>* MemoryMapped<T>::_end()
{
	return start + _size;
}

template<typename T>
inline MemoryMappedDevice<T>::MemoryMappedDevice(void* base, size_t size, const Driver<T>* d)
	:MemoryMapped<T>(base, size)
{
	device = d;
	device->registers = MemoryMapped<T>::_begin();
}

template<typename T>
inline const Driver<T>* MemoryMappedDevice<T>::get_device()
{
	return device;
}
