#pragma once
#include"memory_mapped.h"
#include<assert.h>
#include"try.h"


template<typename T>
struct IOIterator {
	using InnerType = T;
	Memory<T>& operator*();
	Memory<T>* operator->();
	void operator+=(int i);
	operator bool();
protected:
	IOIterator(MemoryMappedIterator<T> first, MemoryMappedIterator<T> last);
	MemoryMappedIterator<T> curr;
	MemoryMappedIterator<T> end;
};

template<typename T>
class FowardIterator : public IOIterator<T> {
public:
	IOIterator<T>* operator++();
	FowardIterator(MemoryMapped<T>*);
};

template<typename T>
class ReverseIterator : public IOIterator<T> {
public:
	IOIterator<T>* operator++();
	ReverseIterator(MemoryMapped<T>*);
};

template<typename T>
class CyclicIterator : public IOIterator<T> {
public:
	IOIterator<T>* operator++();
	CyclicIterator(MemoryMapped<T>*);
private:
	MemoryMappedIterator<T> reset;
};

template<typename T>
class IOUtility {
public:
	static void copy(MemoryMappedIterator<T> first1, MemoryMappedIterator<T> last1,
		MemoryMappedReverseIterator<T> first2);
	static void fill(MemoryMappedIterator<T> first, MemoryMappedIterator<T> last, T);
};

template<class IOIterator>
class ProgrammedInput : public Tryable {
	friend class Timer;
	using T = typename IOIterator::InnerType;
public:
	ProgrammedInput(MemoryMappedDevice<T>* Src, MemoryMapped<T>* Dest);
private:
	void Try() override;
	MemoryMapped<T>* dest;
	MemoryMappedDevice<T>* src;
};

template<class IOIterator>
ProgrammedInput<IOIterator>::ProgrammedInput(MemoryMappedDevice<T>* Src, MemoryMapped<T>* Dest)
	:dest(Dest), src(Src)
{
}

template<class IOIterator>
inline void ProgrammedInput<IOIterator>::Try()
{
	IOIterator iterator{ dest };
	while (src->available() && iterator) {
		auto data = src->get();
		(*iterator).load(data);
		++iterator;
	}
}

template<class IOIterator>
class ProgrammedOutput : public Tryable {
	using T = typename IOIterator::InnerType;
	friend class Timer;
public:
	ProgrammedOutput(MemoryMapped<T>* Src, MemoryMappedDevice<T>* Dest);
private:
	void Try() override;
	MemoryMapped<T>* src;
	MemoryMappedDevice<T>* dest;
};

template<class IOIterator>
inline ProgrammedOutput<IOIterator>::ProgrammedOutput(MemoryMapped<T>* Src, MemoryMappedDevice<T>* Dest)
	:src(Src), dest(Dest)
{
}

template<class IOIterator>
inline void ProgrammedOutput<IOIterator>::Try()
{
	IOIterator iterator{ src };
	dest->update();
	while (dest->available() && iterator) {
		dest->put((*iterator).read());
		++iterator;
	}
}

template<typename T>
inline void IOUtility<T>::copy(MemoryMappedIterator<T> first1, MemoryMappedIterator<T> last1, MemoryMappedReverseIterator<T> first2)
{
}

template<typename T>
inline void IOUtility<T>::fill(MemoryMappedIterator<T> first, MemoryMappedIterator<T> last, T t)
{
	while (first != last) {
		(*first).load(t);
		++first;
	}
}

template<typename T>
inline Memory<T>& IOIterator<T>::operator*()
{
	// TODO: insert return statement here
	return *curr;
}

template<typename T>
inline Memory<T>* IOIterator<T>::operator->()
{
	// TODO: insert return statement here
	return &*curr;
}

template<typename T>
inline void IOIterator<T>::operator+=(int i)
{
	curr += i;
}

template<typename T>
inline IOIterator<T>::operator bool()
{
	return curr != end;
}

template<typename T>
inline IOIterator<T>::IOIterator(MemoryMappedIterator<T> first, MemoryMappedIterator<T> last)
	:curr(first), end(last)
{
}

template<typename T>
inline IOIterator<T>* FowardIterator<T>::operator++()
{
	if (this->curr != this->end)
		++this->curr;
	return this;
}

template<typename T>
inline FowardIterator<T>::FowardIterator(MemoryMapped<T>* mm)
	:IOIterator<T>(mm->begin(), mm->end())
{
}

template<typename T>
inline IOIterator<T>* ReverseIterator<T>::operator++()
{
	MemoryMappedReverseIterator<T>* temp = reinterpret_cast<MemoryMappedReverseIterator<T>*>(&this->curr);
	if (this->curr != this->end)
		temp->operator++();
	return this;
}

template<typename T>
inline ReverseIterator<T>::ReverseIterator(MemoryMapped<T>* mm)
	:IOIterator<T>(mm->rbegin(), mm->rend())
{
}

template<typename T>
inline IOIterator<T>* CyclicIterator<T>::operator++()
{
	++this->curr;
	if (this->curr != this->end)
		this->curr = this->reset;
	return this;
}

template<typename T>
inline CyclicIterator<T>::CyclicIterator(MemoryMapped<T>* mm)
	:IOIterator<T>(mm->begin(), mm->end()), reset(mm->begin())
{
}


